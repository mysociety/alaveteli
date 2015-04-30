require File.join(File.dirname(__FILE__), 'usage')
namespace :config_files do

    include Usage

    def convert_ugly(file, replacements)
        converted_lines = []
        ugly_var = /\!\!\(\*= \$([^ ]+) \*\)\!\!/
        File.open(file, 'r').each do |line|
            line = line.gsub(ugly_var) do |match|
                var = $1.to_sym
                replacement = replacements[var]
                if replacement == nil
                    raise "Unhandled variable in example file: $#{var}"
                else
                    replacements[var]
                end
            end
            converted_lines << line
        end
        converted_lines
    end

    desc 'Convert Debian example init script in config to a form suitable for installing in /etc/init.d'
    task :convert_init_script => :environment do
        example = 'rake config_files:convert_init_script DEPLOY_USER=deploy VHOST_DIR=/dir/above/alaveteli VCSPATH=alaveteli SITE=alaveteli SCRIPT_FILE=config/alert-tracks-debian.example'
        check_for_env_vars(['DEPLOY_USER',
                            'VHOST_DIR',
                            'SCRIPT_FILE'], example)

        replacements = {
            :user => ENV['DEPLOY_USER'],
            :vhost_dir => ENV['VHOST_DIR'],
            :vcspath => ENV.fetch('VCSPATH') { 'alaveteli' },
            :site => ENV.fetch('SITE') { 'foi' },
            :rails_env => ENV.fetch('RAILS_ENV') { 'development' }
        }

        # Use the filename for the $daemon_name ugly variable
        daemon_name = File.basename(ENV['SCRIPT_FILE'], '-debian.example')
        replacements.update(:daemon_name => "#{ replacements[:site] }-#{ daemon_name }")

        # Generate the template for potential further processing
        converted = convert_ugly(ENV['SCRIPT_FILE'], replacements)

        # gsub the RAILS_ENV in to the generated template if its not set by the
        # hard coded config file
        unless File.exists?("#{ Rails.root }/config/rails_env.rb")
            converted.each do |line|
                line.gsub!(/^#\s*RAILS_ENV=your_rails_env/, "RAILS_ENV=#{Rails.env}")
                line.gsub!(/^#\s*export RAILS_ENV/, "export RAILS_ENV")
            end
        end

        converted.each do |line|
            puts line
        end
    end

    desc 'Convert Debian example crontab file in config to a form suitable for installing in /etc/cron.d'
    task :convert_crontab => :environment do
        example = 'rake config_files:convert_crontab DEPLOY_USER=deploy VHOST_DIR=/dir/above/alaveteli VCSPATH=alaveteli SITE=alaveteli CRONTAB=config/crontab-example MAILTO=cron-alaveteli@example.org'
        check_for_env_vars(['DEPLOY_USER',
                            'VHOST_DIR',
                            'VCSPATH',
                            'SITE',
                            'CRONTAB'], example)
        replacements = {
            :user => ENV['DEPLOY_USER'],
            :vhost_dir => ENV['VHOST_DIR'],
            :vcspath => ENV['VCSPATH'],
            :site => ENV['SITE'],
            :mailto => ENV.fetch('MAILTO') { "cron-#{ ENV['SITE'] }@mysociety.org" }
        }
        convert_ugly(ENV['CRONTAB'], replacements).each do |line|
            puts line
        end
    end

end
