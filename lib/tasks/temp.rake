# -*- coding: utf-8 -*-
namespace :temp do

  desc 'Convert serialized params_yaml from PostgreSQL::OID::Integer to ActiveModel::Type::Integer'
  task :update_params_yaml => :environment do
    InfoRequestEvent.where("params_yaml LIKE '%OID::Integer%'").find_each do |event|
      new_params =
        event.params_yaml.gsub('!ruby/object:ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer',
                               '!ruby/object:ActiveModel::Type::Integer')
      event.update(params_yaml: new_params)
    end
  end

  desc 'Populate missing timestamp columns'
  task :populate_missing_timestamps => :environment do
    puts 'Populating FoiAttachment created_at, updated_at'
    FoiAttachment.where(created_at: nil, updated_at: nil).find_each do |foi_attachment|
      value = foi_attachment.try(:incoming_message).try(:last_parsed)
      value ||= foi_attachment.try(:incoming_message).try(:created_at)
      foi_attachment.update_columns(created_at: value, updated_at: value)
    end

    puts 'Populating Holiday created_at, updated_at'
    Holiday.where(created_at: nil, updated_at: nil).find_each do |holiday|
      value = Time.zone.now
      holiday.update_columns(created_at: value, updated_at: value)
    end

    puts 'Populating InfoRequestEvent updated_at'
    InfoRequestEvent.where(updated_at: nil).find_each do |event|
      value = event.created_at
      event.update_columns(updated_at: value)
    end

    puts 'Populating ProfilePhoto created_at, updated_at'
    ProfilePhoto.where(created_at: nil, updated_at: nil).find_each do |photo|
      value = photo.try(:user).try(:created_at)
      photo.update_columns(created_at: value, updated_at: value)
    end

    puts 'Populating PublicBodyCategoryLink created_at, updated_at'
    PublicBodyCategoryLink.where(created_at: nil, updated_at: nil).find_each do |pbcl|
      value = Time.zone.now
      pbcl.update_columns(created_at: value, updated_at: value)
    end

    puts 'Populating PublicBodyCategory created_at, updated_at'
    PublicBodyCategory.where(created_at: nil, updated_at: nil).find_each do |pbc|
      value = Time.zone.now
      pbc.update_columns(created_at: value, updated_at: value)
    end

    puts 'Populating PublicBodyHeading created_at, updated_at'
    PublicBodyHeading.where(created_at: nil, updated_at: nil).find_each do |pbh|
      value = Time.zone.now
      pbh.update_columns(created_at: value, updated_at: value)
    end

    puts 'Populating RawEmail created_at, updated_at'
    RawEmail.where(created_at: nil, updated_at: nil).find_each do |raw_email|
      value = raw_email.try(:incoming_message).try(:created_at)
      raw_email.update_columns(created_at: value, updated_at: value)
    end

    puts 'Populating UserInfoRequestSentAlert created_at, updated_at'
    UserInfoRequestSentAlert.where(created_at: nil, updated_at: nil).find_each do |alert|
      value = alert.try(:info_request_event).try(:created_at)
      alert.update_columns(created_at: value, updated_at: value)
    end

    puts 'Populating HasTagStringTag updated_at'
    HasTagString::HasTagStringTag.where(updated_at: nil).find_each do |tag|
      value = tag.created_at
      tag.update_columns(updated_at: value)
    end

    puts 'Populating ActsAsXapianJob created_at, updated_at'
    ActsAsXapian::ActsAsXapianJob.where(created_at: nil, updated_at: nil).find_each do |job|
      value = Time.zone.now
      job.update_columns(created_at: value, updated_at: value)
    end
  end

  desc 'Populate any missing FoiAttachment files'
  task :populate_missing_attachment_files => :environment do
    verbose = ENV['VERBOSE'] == '1'
    offset = (ENV['OFFSET'] || 0).to_i
    IncomingMessage.find_each(:start => offset) do |incoming_message|
      id = incoming_message.id
      begin
        puts id if verbose
        incoming_message.get_attachment_text_full
        incoming_message.get_text_for_indexing_full
      rescue Errno::ENOENT
        puts "Reparsing" if verbose
        incoming_message.parse_raw_email!(true)
      rescue ArgumentError, Encoding::InvalidByteSequenceError => e
        if verbose
          STDERR.puts "ERROR: #{id} #{e.class}: #{e.message}"
        end
      rescue StandardError => e
        if verbose
          STDERR.puts "UNKNOWN ERROR: #{id} #{e.class}: #{e.message}"
        end
      end
    end
  end

  desc 'Populate last_event_time column of InfoRequest'
  task :populate_last_event_time => :environment do
    InfoRequest.
      where('last_event_time IS NULL').
          includes(:info_request_events).
            find_each do |info_request|
      info_request.update_column(:last_event_time,
        info_request.info_request_events.last.created_at)
    end
  end

  desc 'Remove cached zip download files'
  task :remove_cached_zip_downloads => :environment do
    FileUtils.rm_rf(InfoRequest.download_zip_dir)
  end

  desc 'Audit cached zip download files with censor rules'
  task :audit_cached_zip_downloads_with_censor_rules => :environment do
    puts [
           "Info Request ID",
           "URL Title",
           "Censor rule IDs",
           "Censor rule patterns",
           "Cached file types"
         ].join("\t")
    requests_with_censor_rules.each do |info_request|
      find_cached_zip_downloads(info_request)
    end
  end

  def requests_with_censor_rules
    info_requests_with_rules = CensorRule.
                                where("info_request_id IS NOT NULL").
                                  pluck("info_request_id")
    info_requests_with_user_rules = User.
                                      joins(:censor_rules, :info_requests).
                                        pluck("info_requests.id")
    info_requests_with_public_body_rules = PublicBody.
                                             joins(:censor_rules, :info_requests).
                                               pluck("info_requests.id")
    info_requests_to_audit = (info_requests_with_rules +
                              info_requests_with_user_rules +
                              info_requests_with_public_body_rules).uniq
    InfoRequest.find(info_requests_to_audit)
  end

  def find_cached_zip_downloads(info_request)
    if File.exist?(info_request.download_zip_dir)
      cached_types = []
      cached_zips = Dir.glob(File.join(info_request.download_zip_dir, "**", "*.zip"))
      cached_zips.each do |zip|
        file_name = File.basename(zip, '.zip')
        if file_name =~ /requester_only$/
          cached_types << :requester_only
        elsif file_name =~ /hidden$/
          cached_types << :hidden
        else
          cached_types << :public
        end
      end
      puts [
             info_request.id,
             info_request.url_title,
             info_request.applicable_censor_rules.map { |rule| rule.id }.join(","),
             info_request.applicable_censor_rules.map { |rule| rule.text }.join(","),
             cached_types.uniq.join(",")
           ].join("\t")
    end
  end

  desc 'Populate the last_event_forming_initial_request_id,
        date_initial_request_last_sent_at,
        date_response_required_by and date_very_overdue_after
        fields for all requests'
  task :populate_request_due_dates => :environment do
    ActiveRecord::Base.record_timestamps = false
    begin
      InfoRequest.
        where('last_event_forming_initial_request_id is NULL').
          find_each do |info_request|
        sent_event = info_request.last_event_forming_initial_request
        info_request.last_event_forming_initial_request_id = sent_event.id
        info_request.date_initial_request_last_sent_at = sent_event.created_at.to_date
        info_request.date_response_required_by = info_request.calculate_date_response_required_by
        info_request.date_very_overdue_after = info_request.calculate_date_very_overdue_after
        info_request.save(:validate => false)
      end
    ensure
      ActiveRecord::Base.record_timestamps = true
    end
  end

  def backload_overdue(event_type, verbose)
    UserInfoRequestSentAlert.
      where(['alert_type = ?
              AND info_request_event_id IS NOT NULL',
              "#{event_type}_1"]).
        find_each do |overdue_alert|

      event_forming_request = InfoRequestEvent.find(overdue_alert.info_request_event_id)
      days_to_count = case event_type
                      when 'overdue'
                        overdue_alert.info_request.late_calculator.reply_late_after_days
                      when 'very_overdue'
                        overdue_alert.info_request.late_calculator.reply_very_late_after_days
                      else
                        raise "Unknown event type #{event_type}"
                      end
      due_date = Holiday.due_date_from(event_forming_request.created_at,
                                       days_to_count,
                                       AlaveteliConfiguration.working_or_calendar_days)
      created_at = due_date.beginning_of_day + 1.day

      existing_event = InfoRequestEvent.where("info_request_id = ?
                                              AND event_type = ?
                                              AND created_at > ?",
                                              overdue_alert.info_request,
                                              event_type,
                                              event_forming_request.created_at)
      if existing_event.empty?
        overdue_alert.info_request.log_event(event_type,
          { :event_created_at => Time.zone.now },
          { :created_at => created_at })

        if verbose
          puts "Logging #{event_type} for #{overdue_alert.info_request.id}"
        end
      end
    end
  end

  desc 'Backload overdue InfoRequestEvents'
  task :backload_overdue_info_request_events => :environment do
    verbose = ENV['VERBOSE'] == '1'
    backload_overdue('overdue', verbose)
  end

  desc 'Backload very overdue InfoRequestEvents'
  task :backload_very_overdue_info_request_events => :environment do
    verbose = ENV['VERBOSE'] == '1'
    backload_overdue('very_overdue', verbose)
  end

  desc 'Update EventType when only editing prominence to hide'
  task :update_hide_event_type => :environment do
    InfoRequestEvent.where(:event_type => 'edit').find_each do |event|
      if event.only_editing_prominence_to_hide?
        event.update_attributes!(event_type: "hide")
      end
    end
  end

  desc 'Cache the delivery status of mail server logs'
  task :cache_delivery_status => :environment do
    mta_agnostic_statuses =
      MailServerLog::DeliveryStatus::TranslatedConstants.
        humanized.keys.map(&:to_s)
    MailServerLog.where.not(:delivery_status => mta_agnostic_statuses).find_each do |mail_log|
      mail_log.update_attributes!(:delivery_status => mail_log.delivery_status)
      puts "Cached MailServerLog#delivery_status of id: #{ mail_log.id }"
    end
  end

  desc 'Analyse rails log specified by LOG_FILE to produce a list of request volume'
  task :request_volume => :environment do
    example = 'rake log_analysis:request_volume LOG_FILE=log/access_log OUTPUT_FILE=/tmp/log_analysis.csv'
    check_for_env_vars(['LOG_FILE', 'OUTPUT_FILE'],example)
    log_file_path = ENV['LOG_FILE']
    output_file_path = ENV['OUTPUT_FILE']
    is_gz = log_file_path.include?(".gz")
    urls = Hash.new(0)
    f = is_gz ? Zlib::GzipReader.open(log_file_path) : File.open(log_file_path, 'r')
    processed = 0
    f.each_line do |line|
      line.force_encoding('ASCII-8BIT')
      if request_match = line.match(/^Started (GET|OPTIONS|POST) "(\/request\/.*?)"/)
        next if line.match(/request\/\d+\/response/)
        urls[request_match[2]] += 1
        processed += 1
      end
    end
    url_counts = urls.to_a
    num_requests_visited_n_times = Hash.new(0)
    CSV.open(output_file_path, "wb") do |csv|
      csv << ['URL', 'Number of visits']
      url_counts.sort_by(&:last).each do |url, count|
        num_requests_visited_n_times[count] +=1
        csv << [url,"#{count}"]
      end
      csv << ['Number of visits', 'Number of URLs']
      num_requests_visited_n_times.to_a.sort.each do |number_of_times, number_of_requests|
        csv << [number_of_times, number_of_requests]
      end
      csv << ['Total number of visits']
      csv << [processed]
    end

  end

  desc 'Look for and fix invalid UTF-8 text in various models. Should be run under ruby 1.9 or above'
  task :fix_invalid_utf8 => :environment do

    dryrun = ENV['DRYRUN'] != '0'
    if dryrun
      $stderr.puts "This is a dryrun - nothing will be changed"
    end


    PublicBody.find_each do |public_body|
      unless public_body.name.valid_encoding?
        name = convert_string_to_utf8(public_body.name)
        puts "Bad encoding in PublicBody name, id: #{public_body.id}, " \
          "old name: #{public_body.name.force_encoding('UTF-8')}, new name #{name}"
        unless dryrun
          public_body.name_will_change!
          public_body.name = name
          public_body.last_edit_editor = 'system'
          public_body.last_edit_comment = 'Invalid utf-8 encoding fixed by temp:fix_invalid_utf8'
          public_body.save!
        end
      end

      # Editing old versions of public bodies - we don't want to affect the timestamp
      PublicBody::Version.record_timestamps = false
      public_body.versions.each do |public_body_version|
        unless public_body_version.name.valid_encoding?
          name = convert_string_to_utf8(public_body_version.name).string
          puts "Bad encoding in PublicBody::Version name, " \
            "id: #{public_body_version.id}, old name: #{public_body_version.name.force_encoding('UTF-8')}, " \
            "new name: #{name}"
          unless dryrun
            public_body_version.name_will_change!
            public_body_version.name = name
            public_body_version.save!
          end
        end
      end
      PublicBody::Version.record_timestamps = true

    end

    IncomingMessage.find_each do |incoming_message|
      if (incoming_message.cached_attachment_text_clipped &&
        !incoming_message.cached_attachment_text_clipped.valid_encoding?) ||
         (incoming_message.cached_main_body_text_folded &&
          !incoming_message.cached_main_body_text_folded.valid_encoding?) ||
         (incoming_message.cached_main_body_text_unfolded &&
          !incoming_message.cached_main_body_text_unfolded.valid_encoding?)
        puts "Bad encoding in IncomingMessage cached fields, :id #{incoming_message.id} "
        unless dryrun
          incoming_message.clear_in_database_caches!
        end
      end
    end

    FoiAttachment.find_each do |foi_attachment|
      unescaped_filename = CGI.unescape(foi_attachment.filename)
      unless unescaped_filename.valid_encoding?
        filename = convert_string_to_utf8(unescaped_filename).string
        puts "Bad encoding in FoiAttachment filename, id: #{foi_attachment.id} " \
          "old filename #{unescaped_filename.force_encoding('UTF-8')}, new filename #{filename}"
        unless dryrun
          foi_attachment.filename = filename
          foi_attachment.save!
        end
      end
    end

    OutgoingMessage.find_each do |outgoing_message|
      unless outgoing_message.raw_body.valid_encoding?

        raw_body = convert_string_to_utf8(outgoing_message.raw_body).string
        puts "Bad encoding in OutgoingMessage raw_body, id: #{outgoing_message.id} " \
          "old raw_body: #{outgoing_message.raw_body.force_encoding('UTF-8')}, new raw_body: #{raw_body}"
        unless dryrun
          outgoing_message.body = raw_body
          outgoing_message.save!
        end
      end
    end

    User.find_each do |user|
      unless user.name.valid_encoding?
        name = convert_string_to_utf8(user.name).string
        puts "Bad encoding in User name, id: #{user.id}, " \
          "old name: #{user.name.force_encoding('UTF-8')}, new name: #{name}"
        unless dryrun
          user.name = name
          user.save!
        end
      end
    end

  end

  desc 'Set reject_incoming_at_mta on a list of requests identified by request address'
  task :set_reject_incoming_at_mta_from_list => :environment do
    example = 'rake temp:set_reject_incoming_at_mta_from_list FILE=/tmp/rejection_list.txt'
    check_for_env_vars(['FILE'], example)
    f = File.read(ENV['FILE'])
    f.each_line do |line|
      info_request = InfoRequest.find_by_incoming_email(line.strip)
      info_request.reject_incoming_at_mta = true
      info_request.save!
    end
  end

  desc 'Look for a fix requests with line breaks in titles'
  task :remove_line_breaks_from_request_titles => :environment do
    InfoRequest.where("title LIKE ? OR title LIKE ?", "%\n%", "%\r%").
                each { |request| request.save! }
  end

  desc "Generate request summaries for every user"
  task :generate_request_summaries => :environment do
    User.find_each do |user|
      user.info_requests.each do |request|
        request.create_or_update_request_summary
      end
      user.draft_info_requests.each do |request|
        request.create_or_update_request_summary
      end
      user.info_request_batches.each do |request|
        request.create_or_update_request_summary
      end
      user.draft_info_request_batches.each do |request|
        request.create_or_update_request_summary
      end
    end
  end

  desc 'Set use_notifications to false on all existing requests'
  task :set_use_notifications => :environment do
    InfoRequest.update_all use_notifications: false
  end

  desc 'Set a default time for users daily summary notifications'
  task :set_daily_summary_times => :environment do
    query = "UPDATE users " \
            "SET daily_summary_hour = floor(random() * 24), " \
            "daily_summary_minute = floor(random() * 60)"
    ActiveRecord::Base.connection.execute(query)
  end

  desc 'Remove notifications_tester role'
  task :remove_notifications_tester_role => :environment do
    if Role.where(name: 'notifications_tester').exists?
      Role.where(name: 'notifications_tester').destroy_all
    end
  end
end
