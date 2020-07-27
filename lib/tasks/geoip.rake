namespace :geoip do
  require 'open-uri'

  def log(text)
    puts(text) unless Rake.application.options.silent
  end

  desc 'Download the latest MaxMind geoip data file'
  task download_data: :environment do
    target_dir = Rails.root.join('vendor/data')
    destination = target_dir.join('GeoLite2-Country.mmdb')
    relative_destination = destination.relative_path_from(Rails.root).to_s

    if AlaveteliConfiguration.geoip_database != relative_destination
      log 'Skipping MaxMind geoip data file download as GEOIP_DATABASE has ' \
          'been set in config/general.yml to a non-default value'

      next

    elsif AlaveteliConfiguration.maxmind_license_key.blank?
      log 'Can\'t download the latest MaxMind geoip data file. Please add ' \
          'MAXMIND_LICENSE_KEY setting to config/general.yml'

      next
    end

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

    Dir.mktmpdir('geodata') do |tmp_dir|
      downloaded_location = File.join(tmp_dir, 'geodata.tar.gz')

      File.open(downloaded_location, "wb") do |saved_file|
        begin
          # the following "open" is provided by open-uri
          open(link, "rb") do |read_file|
            saved_file.write(read_file.read)
          end

        rescue OpenURI::HTTPError => ex
          log 'Error downloading MaxMind geoip data file'
          log "  #{ex.message}"

          if ex.message == '401 Unauthorized'
            log 'Please check the MAXMIND_LICENSE_KEY setting in ' \
                'config/general.yml'
          end

          exit
        end
      end

      `tar -xzf #{downloaded_location} -C #{tmp_dir}`

      unless File.exist?(target_dir)
        FileUtils.mkdir target_dir
      end

      extracted_folder = Dir["#{tmp_dir}/GeoLite2-Country_*"].last
      FileUtils.mv("#{extracted_folder}/GeoLite2-Country.mmdb", destination)
    end

    log 'MaxMind geoip data file downloaded'

    unless AlaveteliConfiguration.geoip_database != relative_destination
      log 'Please make sure config/general.yml has the following setting:'
      log "  GEOIP_DATABASE: #{relative_destination}"
    end
  end
end
