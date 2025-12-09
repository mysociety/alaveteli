namespace :temp do
  desc 'Populate User#status_update_count'
  task populate_user_status_update_count: :environment do
    scope = User.all
    count = scope.count

    scope.find_each.with_index do |user, index|
      update_count = InfoRequestEvent.
        where(event_type: 'status_update').
        where("params -> 'user' ->> 'gid' = ?", user.to_gid.to_s).
        count

      user.update_columns(status_update_count: update_count)

      erase_line
      print "Populating User#status_update_count #{index + 1}/#{count}"
    end

    erase_line
    puts "Populating User#status_update_count completed."
  end

  desc 'Migrate cache columns from incoming_messages to raw_emails'
  task migrate_cache_columns_to_raw_emails: :environment do
    scope = IncomingMessage.where.not(last_parsed: nil).
      joins(:raw_email).where(raw_emails: { message_id: nil }).
      includes(raw_email: :file_blob)
    count = scope.count

    puts "Migrating cache columns for #{count} incoming messages..."

    scope.find_each.with_index do |incoming_message, index|
      raw_email = incoming_message.raw_email

      next unless raw_email.send(:should_cache_attributes?)

      raw_email.send(:cache_attributes_from_mail)
      raw_email.save!

      erase_line
      print "Migrating cache columns #{index + 1}/#{count}"
    end

    erase_line
    puts "Migrating cache columns completed."
  end

  def erase_line
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences
    print "\e[1G\e[K"
  end
end
