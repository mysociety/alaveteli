
namespace :themes do

    def plugin_dir
        File.join(Rails.root,"lib","themes")
    end

    def theme_dir(theme_name)
        File.join(plugin_dir, theme_name)
    end

    def old_theme_dir(theme_name)
        File.join(Rails.root, "vendor", "plugins", theme_name)
    end

    def possible_theme_dirs(theme_name)
        [theme_dir(theme_name), old_theme_dir(theme_name)]
    end

    def checkout(commitish)
        puts "Checking out #{commitish}" if verbose
        system "git checkout #{commitish}"
    end

    def checkout_tag(version)
        checkout usage_tag(version)
    end

    def checkout_remote_branch(branch)
        checkout "origin/#{branch}"
    end

    def usage_tag(version)
        "use-with-alaveteli-#{version}"
    end

    def install_theme_using_git(name, uri, verbose=false, options={})
        install_path = theme_dir(name)
        Dir.chdir(plugin_dir) do
            clone_command = "git clone #{uri} #{name}"
            if system(clone_command)
                Dir.chdir install_path do
                    # First try to checkout a specific branch of the theme
                    tag_checked_out = checkout_remote_branch(AlaveteliConfiguration::theme_branch) if AlaveteliConfiguration::theme_branch
                    if !tag_checked_out
                        # try to checkout a tag exactly matching ALAVETELI VERSION
                        tag_checked_out = checkout_tag(ALAVETELI_VERSION)
                    end
                    if ! tag_checked_out
                        # if we're on a hotfix release (four sequence elements or more),
                        # look for a usage tag matching the minor release (three sequence elements)
                        # and check that out if found
                        if hotfix_version = /^(\d+\.\d+\.\d+)(\.\d+)+/.match(ALAVETELI_VERSION)
                            base_version = hotfix_version[1]
                            tag_checked_out = checkout_tag(base_version)
                        end
                    end
                    if ! tag_checked_out
                        puts "No specific tag for this version: using HEAD" if verbose
                    end
                    puts "removing: .git .gitignore" if verbose
                    rm_rf %w(.git .gitignore)
                end
            else
                rm_rf install_path
                raise "#{clone_command} failed! Stopping."
            end
        end
    end

    def uninstall(theme_name, verbose=false)
        possible_theme_dirs(theme_name).each do |dir|
            if File.directory?(dir)
                run_hook(theme_name, 'uninstall', verbose)
                puts "Removing '#{dir}'" if verbose
                rm_r dir
            else
                puts "Plugin doesn't exist: #{dir}"
            end
        end
    end

    def run_hook(theme_name, hook_name, verbose=false)
        hook_file = File.join(theme_dir(theme_name), "#{hook_name}.rb")
        if File.exist? hook_file
            puts "Running #{hook_name} hook for #{theme_name}" if verbose
            load hook_file
        end
    end

    def installed?(theme_name)
        possible_theme_dirs(theme_name).any? { |dir| File.directory? dir }
    end

    def install_theme(theme_url, verbose, deprecated=false)
        FileUtils.mkdir_p plugin_dir
        deprecation_string = deprecated ? " using deprecated THEME_URL" : ""
        theme_name = theme_url_to_theme_name theme_url
        puts "Installing theme #{theme_name}#{deprecation_string} from #{theme_url}"
        uninstall(theme_name, verbose) if installed?(theme_name)
        install_theme_using_git(theme_name, theme_url, verbose)
        run_hook(theme_name, 'install', verbose)
        run_hook(theme_name, 'post_install', verbose)
    end

    desc "Install themes specified in the config file's THEME_URLS"
    task :install => :environment do
        verbose = true
        AlaveteliConfiguration::theme_urls.each{ |theme_url| install_theme(theme_url, verbose) }
        if ! AlaveteliConfiguration::theme_url.blank?
            # Old version of the above, for backwards compatibility
            install_theme(AlaveteliConfiguration::theme_url, verbose, deprecated=true)
        end
    end
end
