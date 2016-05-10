# -*- encoding : utf-8 -*-
require Rails.root.join('commonlib', 'rblib', 'git')

namespace :themes do

  # Alias the module so we don't need the MySociety prefix here
  Git = MySociety::Git

  def all_themes_dir
    File.join(Rails.root,"lib","themes")
  end

  def theme_dir(theme_name)
    File.join(all_themes_dir, theme_name)
  end

  def old_all_themes_dir(theme_name)
    File.join(Rails.root, "vendor", "plugins", theme_name)
  end

  def possible_theme_dirs(theme_name)
    [theme_dir(theme_name), old_all_themes_dir(theme_name)]
  end

  def installed?(theme_name)
    possible_theme_dirs(theme_name).any? { |dir| File.directory? dir }
  end

  def usage_tag(version)
    "use-with-alaveteli-#{version}"
  end

  def uninstall(theme_name, verbose=false)
    possible_theme_dirs(theme_name).each do |dir|
      if File.directory?(dir)
        run_hook(theme_name, 'uninstall', verbose)
      end
    end
  end

  def run_hook(theme_name, hook_name, verbose=false)
    directory = theme_dir(theme_name)
    hook_file = File.join(directory, "#{hook_name}.rb")
    if File.exist? hook_file
      puts "Running #{hook_name} hook in #{directory}" if verbose
      load hook_file
    end
  end

  def move_old_theme(old_theme_directory)
    puts "There was an old-style theme at #{old_theme_directory}" if verbose
    moved_directory = "#{old_theme_directory}-moved"
    begin
      File.rename old_theme_directory, moved_directory
    rescue Errno::ENOTEMPTY, Errno::EEXIST
      raise "Tried to move #{old_theme_directory} out of the way, " \
        "but #{moved_directory} already existed"
    end
  end

  def committishes_to_try
    result = []
    theme_branch = AlaveteliConfiguration::theme_branch
    result.push "origin/#{theme_branch}" if theme_branch
    result.push usage_tag(ALAVETELI_VERSION)
    hotfix_match = /^(\d+\.\d+\.\d+)(\.\d+)+/.match(ALAVETELI_VERSION)
    result.push usage_tag(hotfix_match[1]) if hotfix_match
    minor_match = /^(\d+\.\d+)(\.\d+)+/.match(ALAVETELI_VERSION)
    result.push usage_tag(minor_match[1]) if minor_match
    result
  end

  def checkout_best_option(theme_name)
    theme_directory = theme_dir theme_name
    all_failed = true
    committishes_to_try.each do |committish|
      if Git.committish_exists? theme_directory, committish
        puts "Checking out #{committish}" if verbose
        Git.checkout theme_directory, committish
        all_failed = false
        break
      else
        puts "Failed to find #{committish}; skipping..." if verbose
      end
    end
    puts "Falling to using HEAD instead" if all_failed and verbose
  end

  def install_theme(theme_url, verbose, deprecated=false)
    FileUtils.mkdir_p all_themes_dir
    deprecation_string = deprecated ? " using deprecated THEME_URL" : ""
    theme_name = theme_url_to_theme_name theme_url
    puts "Installing theme #{theme_name}#{deprecation_string} from #{theme_url}"
    # Make sure any uninstall hooks have been run:
    uninstall(theme_name, verbose) if installed?(theme_name)
    theme_directory = theme_dir theme_name
    # Is there an old-style theme directory there?  If so, move it
    # out of the way so that there's no risk that work is lost:
    if File.directory? theme_directory
      unless Git.non_bare_repository? theme_directory
        move_old_theme theme_directory
      end
    end
    # If there isn't a directory there already, clone it into place:
    unless File.directory? theme_directory
      unless system "git", "clone", theme_url, theme_directory
        raise "Cloning from #{theme_url} to #{theme_directory} failed"
      end
    end
    # Set the URL for origin in case it has changed, and fetch from there:
    Git.remote_set_url theme_directory, 'origin', theme_url
    Git.fetch theme_directory, 'origin'
    # Check that checking-out a new commit will be safe:
    unless Git.status_clean theme_directory
      raise "There were uncommitted changes in #{theme_directory}"
    end
    unless Git.is_HEAD_pushed? theme_directory
      raise "The current work in #{theme_directory} is unpushed"
    end
    # Now try to checkout various commits in order of preference:
    checkout_best_option theme_name
    # Finally run the install hooks:
    run_hook(theme_name, 'install', verbose)
    run_hook(theme_name, 'post_install', verbose)
    puts "#{theme_name} successfully installed in: #{theme_directory}"
    puts ""
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


  def locale_extensions(locale)
    locale_extensions = if locale == I18n.default_locale
      ['']
    else
      [".#{locale}"]
    end
    if locale != I18n.default_locale && locale.to_s.include?('_')
      locale_extensions << ".#{locale.to_s.split('_').first}"
    end
    locale_extensions
  end

  def template_file(template_name, theme_name, locale)
    locale_extensions(locale).each do |locale_extension|
      filename = "#{template_name}#{locale_extension}.html.erb"
      filepath = "lib/themes/#{theme_name}/lib/views/help/#{filename}"
      if File.exists?(filepath)
        return filepath
      end
    end
    nil
  end

  def missing_help_info?(help_template_info, locale, theme_name)
    template_file = template_file(help_template_info[:name], theme_name, locale)
    missing_templates = []
    missing_sections = []
    if !template_file
      missing_templates <<  template_file
      puts "Missing help template:  #{help_template_info[:name]} #{locale}"
    else
      contents = File.read(template_file)
      help_template_info[:sections].each do |section|
        if !contents.include?("##{section}")
          missing_sections << section
          puts "Missing section: #{section} in template #{help_template_info[:name]}"
        end
      end
    end
    if missing_templates.empty? && missing_sections.empty?
      false
    else
      true
    end
  end

  desc "Check that all help sections referred to in the application are present in theme"
  task :check_help_sections => :environment do

  intro_message = <<-EOF

Checking that all help templates linked to from Alaveteli are present in the theme,
and that all sections linked to from Alaveteli are present in the templates. For
missing templates, see the examples in the alavetelitheme theme. For
missing sections, create a section in the relevant template. For example, if the
section 'example' is listed as missing, create a section with the following HTML
structure:

  <dt id="example">Section title <a href="#example">#</a> </dt>
  <dd>Contents of the section
  </dd>

EOF
    puts intro_message
    theme_names = AlaveteliConfiguration::theme_urls.map do |theme_url|
      theme_url_to_theme_name(theme_url)
    end

    help_templates_info = [{:name => 'about',
                            :sections => ['whybother_them']},
                           {:name => 'alaveteli',
                            :sections => []},
                           {:name => 'api',
                            :sections => []},
                           {:name => 'contact',
                            :sections => []},
                           {:name => 'credits',
                            :sections => ['helpus']},
                           {:name => 'officers',
                            :sections => ['copyright']},
                           {:name => 'privacy',
                            :sections => ['email_address',
                                          'full_address',
                                          'postal_answer',
                                          'public_request',
                                          'real_name'
                                          ]},
                           {:name => 'requesting',
                            :sections => ['focused',
                                          'data_protection',
                                          'missing_body',
                                          'quickly_response',
                                          ]},
                           {:name => 'unhappy',
                            :sections => ['internal_review',
                                          'other_means'
                                          ]},
                           {:name => '_why_they_should_reply_by_email',
                            :sections => []}]
    theme_names.each do |theme_name|
      I18n.available_locales.each do |locale|
        puts ""
        puts "theme: #{theme_name} locale: #{locale}"
        puts ""
        missing = false
        help_templates_info.each do |help_template_info|
          if missing_help_info?(help_template_info, locale, theme_name)
            missing = true
          end
        end
        if !missing
          puts "No missing templates or sections"
        end
      end
    end

  end

end
