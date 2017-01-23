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

end
