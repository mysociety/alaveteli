namespace :geoip do
  require 'open-uri'

  desc 'Download the latest MaxMind geoip data file'
  task download_data: :environment do
    # download location as documented at:
    #   https://dev.maxmind.com/geoip/geoip2/geolite2/
    link = URI::HTTPS.build(
      host: 'download.maxmind.com',
      path: '/app/geoip_download',
      query: {
        edition_id: 'GeoLite2-Country',
        license_key: AlaveteliConfiguration.maxmind_license_key,
        suffix: 'tar.gz'
      }.to_query
    )

    target_dir = "#{Rails.root}/vendor/data"

    Dir.mktmpdir('geodata') do |tmp_dir|
      downloaded_location = File.join(tmp_dir, 'geodata.tar.gz')

      File.open(downloaded_location, "wb") do |saved_file|
        # the following "open" is provided by open-uri
        open(link, "rb") do |read_file|
          saved_file.write(read_file.read)
        end
      end

      `tar -xzf #{downloaded_location} -C #{tmp_dir}`

      unless File.exist?(target_dir)
        FileUtils.mkdir target_dir
      end

      extracted_folder = Dir["#{tmp_dir}/GeoLite2-Country_*"].last
      FileUtils.mv("#{extracted_folder}/GeoLite2-Country.mmdb",
                   "#{target_dir}/GeoLite2-Country.mmdb")
    end

    unless Rake.application.options.silent
      $stdout.puts 'File downloaded!'
      $stdout.puts 'Please make sure your config.yml has the following setting:'
      $stdout.puts '  GEOIP_DATABASE: vendor/data/GeoLite2-Country.mmdb'
    end
  end
end
