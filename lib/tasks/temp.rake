# -*- coding: utf-8 -*-
namespace :temp do

  desc 'Remove cached zip download files'
  task :remove_cached_zip_downloads => :environment do
    FileUtils.rm_rf(InfoRequest.download_zip_dir)
  end

  desc 'Audit cached zip download files with censor rules'
  task :audit_cached_zip_downloads_with_censor_rules => :environment do
    puts [ "Info Request ID",
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
    if File.exists?(info_request.download_zip_dir)
      cached_types = []
      cached_zips = Dir.glob(File.join(info_request.download_zip_dir, "**", "*.zip"))
      cached_zips.each do |zip|
        file_name = File.basename(zip, '.zip')
        if file_name.ends_with('requester_only')
          cached_types << :requester_only
        elsif file_name.ends_with('hidden')
          cached_types << :hidden
        else
          cached_types << :public
        end
      end
      puts [ info_request.id,
             info_request.url_title,
             info_request.applicable_censor_rules.map{ |rule| rule.id }.join(","),
             info_request.applicable_censor_rules.map{ |rule| rule.text }.join(","),
             cached_types.uniq.join(",")
           ].join("\t")
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
      line.force_encoding('ASCII-8BIT') if RUBY_VERSION.to_f >= 1.9
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
end
