# -*- encoding : utf-8 -*-
namespace :xapian do
  namespace :restore do
    desc <<-EOF.strip_heredoc
    Search through all events and add ones that need reindexing to the queue.

    Finds InfoRequestEvents where activity has happened since the restored
    Xapian backup. A START_AT_ID and FINISH_AT_ID can be specified in order to
    iterate through lots of events in parallel:

    #!/bin/sh
    # tmp/parallel_index_events.sh
    START_AT_ID=1  FINISH_AT_ID=25 rake xapian:restore:queue_events_to_reindex &
    START_AT_ID=25 FINISH_AT_ID=50 rake xapian:restore:queue_events_to_reindex &
    # etc…

    wait
    echo "All processes complete"

    The batch size you choose will depend on the number of InfoRequestEvent
    records you have, but we've run this successfully in batches of 250000.
    EOF
    task :queue_events_to_reindex => :environment do
      xapian_backup_date = Time.zone.parse(ENV.fetch('XAPIAN_BACKUP_DATE'))

      start_at = ENV.fetch('START_AT_ID') { InfoRequestEvent.minimum(:id) }
      finish_at = ENV.fetch('FINISH_AT_ID') { InfoRequestEvent.maximum(:id) }

      start_at = Integer(start_at)
      finish_at = Integer(finish_at)

      puts "STARTING_AT: #{start_at}"
      puts "FINISHING_AT: #{finish_at}"

      InfoRequestEvent.where(id: start_at..finish_at).find_each do |event|
        puts "Checking InfoRequestEvent: #{event.id}"

        # Events always have an InfoRequest
        info_request = event.info_request
        # Events always have a PublicBody via the InfoRequest
        public_body = info_request.public_body
        # Ignoring User, because it gets updated_at touched _all the time_

        # We know an event only has one of these, so :
        # * try to fetch them all
        # * compact out the nils
        # * return the first item in the array, which will either be an
        #   associated record or nil
        association = [event.incoming_message,
                       event.outgoing_message,
                       event.comment].compact.first

        # If the association has an updated_at, compare it to the backup date
        # and return a Boolean
        association_needs_reindex =
          if association.respond_to?(:updated_at)
            association.updated_at >= xapian_backup_date
          else
            false
          end

        # If any of the cases are true, we'll want to reindex the event
        needs_reindex = event.created_at >= xapian_backup_date ||
                        info_request.updated_at >= xapian_backup_date ||
                        public_body.updated_at >= xapian_backup_date ||
                        association_needs_reindex

        # Put a job in the reindex queue if we want to reindex the event
        if needs_reindex
          event.xapian_mark_needs_index
        end
      end
    end

    desc <<-EOF
    Remove indexed records that no longer exist in the relational database.

    As we're restoring from a backup, some indexed records will exist in the
    Xapian database that have been removed from the relational database. These
    would have been removed by regular housekeeping tasks, so we'll need to
    remove them manually.
    EOF
    task :queue_obsolete_indexes_for_removal => :environment do
      [InfoRequestEvent, PublicBody, User].each do |model_class|
        max_id = model_class.maximum(:id)
        instance = model_class.new

        missing_ids = model_class.connection.execute(<<-SQL.strip_heredoc)
        SELECT all_ids
        AS id
        FROM generate_series(
          (SELECT MIN(id)
           FROM #{ model_class.table_name }),
          (SELECT MAX(id)
           FROM #{ model_class.table_name })
        ) all_ids
        EXCEPT
          SELECT id
          FROM #{ model_class.table_name }
        SQL

        missing_ids = missing_ids.map { |element| element['id'] }

        missing_ids.each do |missing_id|
          model_base_class = model_class.base_class.to_s

          msg = <<-EOF.strip_heredoc
          Scheduling #{model_class} missing_id #{missing_id} for index removal
          EOF

          puts msg
          instance.xapian_create_job('destroy', model_base_class, missing_id)
        end
      end
    end

    desc <<-EOF
    Search through various models to queue records that might need reindexing.

    This task is a bit of a "belt-and-braces" task to catch things that need
    reindexing that wouldn't have been indexed in :queue_events_to_reindex.
    The most obvious of these are PublicBody and User records, but also extends
    to records that may changed the indexed state of another record – applying
    an Embargo to an InfoRequest for example.
    EOF
    task :second_pass => :environment do
      xapian_backup_date = Time.zone.parse(ENV.fetch('XAPIAN_BACKUP_DATE'))

      # Reindex anything that's embargoed to make sure its not in the index
      puts 'Checking AlaveteliPro::Embargo'
      AlaveteliPro::Embargo.find_each do |embargo|
        embargo.info_request.try(:reindex_request_events)
      end

      # Reindex anything affected by a censor rule
      # Note that we're not expiring the database/filesystem caches
      puts 'Checking CensorRule'
      CensorRule.find_each do |censor_rule|
        if censor_rule.info_request
          censor_rule.info_request.reindex_request_events
        elsif censor_rule.user
          censor_rule.user.info_requests.each(&:reindex_request_events)
        elsif censor_rule.public_body
          censor_rule.public_body.info_requests.each(&:reindex_request_events)
        else # global rule
          InfoRequest.find_in_batches do |group|
            group.each { |request| request.reindex_request_events }
          end
        end
      end

      # Reindex public bodies created after the backup
      puts 'Checking PublicBody'
      PublicBody.
        where('created_at >= ?', xapian_backup_date).find_each do |public_body|
          public_body.xapian_mark_needs_index
      end

      # Reindex users created after the backup
      puts 'Checking User'
      User.where('created_at >= ?', xapian_backup_date).find_each do |user|
        user.xapian_mark_needs_index
      end

      # Reindex anything that did have an embargo to make sure its in the
      # correct state now
      # See https://github.com/mysociety/alaveteli-professional/issues/384#issuecomment-338209002
      puts 'Checking embargoed info requests'
      embargoed = InfoRequest.
        joins(:info_request_events).
        includes(:embargo).
        references('embargo').
        references(:info_request_events).
        where(info_request_events: { event_type: 'set_embargo' },
              embargoes: { info_request_id: nil })

      embargoed.each { |req| req.reindex_request_events }

      # Reindex whole requests where messages have been edited or removed since
      # the xapian backup date
      puts 'Checking edit and destroy info request events'
      event_types = ['edit_outgoing', 'edit_incoming', 'destroy_incoming']
      InfoRequestEvent.
        where(event_type: event_types).
        where('created_at >= ?', xapian_backup_date).each do |event|
          event.info_request.reindex_request_events
      end

      # Update all events belonging to public bodies where the URL name has
      # changed since the restored backup.
      puts 'Checking updated PublicBody#url_name'
      PublicBody::Version.
        where('updated_at >= ?', xapian_backup_date).each do |version|
          if version.url_name != version.public_body.url_name
            version.public_body.info_requests.each do |info_request|
              info_request.info_request_events.each do |info_request_event|
                info_request_event.xapian_mark_needs_index
              end
            end
          end
      end
    end
  end
end
