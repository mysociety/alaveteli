namespace :config_files do

    def usage_message message
        puts ''
        puts message
        puts ''
        exit 0
    end

    def check_for_env_vars(env_vars, example)
        missing = []
        env_vars.each do |env_var|
            unless ENV[env_var]
                missing << env_var
            end
        end
        if !missing.empty?
            usage = "Usage: This task requires #{env_vars.to_sentence} - missing #{missing.to_sentence}"
            if example
                usage += "\nExample: #{example}"
            end
            usage_message usage
        end
    end

    def convert_ugly(file, replacements)
        converted_lines = []
        ugly_var = /\!\!\(\*= \$([^ ]+) \*\)\!\!/
        File.open(file, 'r').each do |line|
            line = line.gsub(ugly_var) do |match|
                var = $1.to_sym
                replacement = replacements[var]
                if replacement == nil
                    if ! (skip[var] == true)
                        raise "Unhandled variable in .ugly file: $#{var}"
                    else
                        match
                    end
                else
                    replacements[var]
                end
            end
            converted_lines << line
        end
        converted_lines
    end

    desc 'Convert Debian .ugly init script in config to a form suitable for installing in /etc/init.d'
    task :convert_init_script => :environment do
        example = 'rake config_files:convert_init_script DEPLOY_USER=deploy VHOST_DIR=/dir/above/alaveteli SCRIPT_FILE=config/alert-tracks-debian.ugly '
        check_for_env_vars(['DEPLOY_USER', 'VHOST_DIR', 'SCRIPT_FILE'], example)

        deploy_user = ENV['DEPLOY_USER']
        vhost_dir = ENV['VHOST_DIR']
        script_file = ENV['SCRIPT_FILE']

        replacements = { :user => deploy_user,
                         :vhost_dir => vhost_dir }

        daemon_name = File.basename(script_file, '-debian.ugly')
        replacements.update(:daemon_name => "foi-#{daemon_name}")
        converted = convert_ugly(script_file, replacements)
        rails_env_file = File.expand_path(File.join(Rails.root, 'config', 'rails_env.rb'))
        if !File.exists?(rails_env_file)
            converted.each do |line|
                line.gsub!(/^#\s*RAILS_ENV=your_rails_env/, "RAILS_ENV=#{Rails.env}")
                line.gsub!(/^#\s*export RAILS_ENV/, "export RAILS_ENV")
            end
        end
        converted.each do |line|
            puts line
        end
    end


end