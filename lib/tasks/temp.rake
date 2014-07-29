namespace :temp do

    desc 'Rewrite cached HTML attachment headers to use responsive CSS'
    task :responsive_attachments => :environment do
        example = 'rake responsive_attachments PATTERN="./cache/views/request/*/*/response/*/attach/html/*/*.html"'
        check_for_env_vars(['PATTERN'],example)
        pattern = ENV['PATTERN']
        replacement_head_content = <<-EOF
<!--[if LTE IE 7]>
<link href="/assets/responsive/application-lte-ie7.css" media="all" rel="stylesheet" title="Main" type="text/css" />
<![endif]-->

<!--[if IE 8]>
<link href="/assets/responsive/application-ie8.css" media="all" rel="stylesheet" title="Main" type="text/css" />
<![endif]-->

<!--[if GT IE 8]><!-->
<link href="/assets/responsive/application.css" media="all" rel="stylesheet" title="Main" type="text/css" />
<!--<![endif]-->

<script type="text/javascript" src="//use.typekit.net/csi1ugd.js"></script>
<script type="text/javascript">try{Typekit.load();}catch(e){}</script>
EOF


        Dir.glob(pattern) do |cached_html_file|
            puts cached_html_file
            text = File.read(cached_html_file)
            text.sub!(/<link [^>]*href="(\/assets\/application.css|\/stylesheets\/main.css|https?:\/\/www.whatdotheyknow.com\/stylesheets\/main.css)[^>]*>/, replacement_head_content)
            text.sub!(/<\/div>(\s*This is an HTML version of an attachment to the Freedom of Information request.*?)<\/div>/m, '</div><p class="view_html_description">\1</p></div>')
            File.open(cached_html_file, 'w') { |file| file.write(text) }
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
