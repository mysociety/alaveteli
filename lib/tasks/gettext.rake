# -*- encoding : utf-8 -*-
namespace :gettext do

  # TODO: Move to config/initializers/gettext_i18n_rails.rb.
  # Might have to name the file 1_gettext_i18n_rails.rb so that its loaded
  # first.
  # Keep TRANSLATORS comments
  Rails.application.config.gettext_i18n_rails.xgettext = %w[--add-comments=TRANSLATORS:]
  # Disable fuzzy .po merging
  Rails.application.config.gettext_i18n_rails.msgmerge = %w[--no-fuzzy-matching]

  tasks = Rake.application.instance_variable_get '@tasks'
  tasks.delete 'gettext:find'
  tasks.delete 'gettext:setup'

  def clean_dir(dir)
    Dir.glob("#{dir}/*/app.po") do |po_file|
      GetText::Tools::MsgMerge.run("--output", po_file,
                                   "--sort-output",
                                   "--no-location",
                                   "--no-wrap",
                                   # "--no-fuzzy-matching",
                                   po_file,
                                   po_file)
    end
  end

  desc 'Rewrite .po files into a consistent msgmerge format'
  task :clean do
    # find locale/* -name *.po | xargs -I % msgattrib --no-obsolete -o % %
    # Rake::Task["gettext:remove_fuzzy"].invoke
    clean_dir('locale')
  end

  desc "Update pot/po files"
  task :find => :environment do
    def locale_path
      path = FastGettext.translation_repositories[text_domain].instance_variable_get(:@options)[:path] rescue nil
      path || File.join(Rails.root, "locale")
    end

    def files_to_translate
      files = ::Rake::FileList.new("{app,lib,config,#{locale_path}}/**/*.{rb,erb}") do |fl|
        fl.exclude(/\balaveteli_pro\b/)
      end
      files
    end

    # HACK: Update modified time to force gettext to find changes every time
    # https://github.com/grosser/gettext_i18n_rails/issues/120
    files_to_translate.each { |f| FileUtils.touch(f) }

    CLEAN = FileList["locale/*/*~",
                     "locale/*/*.bak",
                     "locale/*/*.time_stamp",
                     "locale/*/*.edit.po"]

    GetText::Tools::Task.define do |task|
      task.package_name = text_domain
      task.package_version = "1.0.0"
      task.domain = text_domain
      task.po_base_directory = locale_path
      task.mo_base_directory = locale_path
      task.files = files_to_translate
      task.enable_description = false
      task.msgmerge_options = gettext_msgmerge_options
      task.msgcat_options = gettext_msgcat_options
      task.xgettext_options = gettext_xgettext_options
    end

    Rake::Task["gettext:po:update"].invoke
    # Remove obsolete
    # Remove fuzzy
    Rake::Task["gettext:clean"].invoke
  end


  desc 'Rewrite Alaveteli Pro .po files into a consistent msgmerge format'
  task :clean_alaveteli_pro do
    load_gettext
    clean_dir('locale_alaveteli_pro')
  end

  desc "Update pot/po files for a theme."
  task :find_theme => :environment do
    theme = find_theme(ENV['THEME'])
    load_gettext
    msgmerge = Rails.application.config.gettext_i18n_rails.msgmerge
    msgmerge ||= %w[--sort-output --no-location --no-wrap]
    GetText.update_pofiles_org(
      text_domain,
      theme_files_to_translate(theme),
      "version 0.0.1",
      :po_root => theme_locale_path(theme),
      :msgmerge => msgmerge
    )
  end

  desc "Update pot/po files for Alaveteli Pro."
  task :find_alaveteli_pro => :environment do
    load_gettext
    msgmerge = Rails.application.config.gettext_i18n_rails.msgmerge
    msgmerge ||= %w[--sort-output --no-location --no-wrap]
    GetText.update_pofiles_org(
      text_domain,
      pro_files_to_translate,
      "version 0.0.1",
      :po_root => pro_locale_path,
      :msgmerge => msgmerge
    )
  end

  desc 'Rewrite theme .po files into a consistent msgmerge format'
  task :clean_theme do
    theme = find_theme(ENV['THEME'])
    load_gettext
    clean_dir(theme_locale_path(theme))
  end

  desc 'Remove fuzzy translations'
  task :remove_fuzzy do
    require "alaveteli_gettext/fuzzy_cleaner.rb"
    fuzzy_cleaner = AlaveteliGetText::FuzzyCleaner.new

    Dir.glob("locale/**/app.po").each do |po_file|
      lines = File.read(po_file)
      output = fuzzy_cleaner.clean_po(lines)
      File.open(po_file, "w") { |f| f.puts(output) }
    end
  end

  desc 'Update locale files with slightly changed English msgids using a csv file of old to new strings'
  task :update_msgids_from_csv do
    mapping_file = find_mapping_file(ENV['MAPPING_FILE'])
    mappings = {}
    CSV.parse(clean_csv_mapping_file(mapping_file)) do |csv_line|
      from,to = csv_line
      mappings[from] = to
    end
    Dir.glob("locale/**/app.po").each do |po_file|
      lang_mappings = mappings.clone
      lines = []
      File.read(po_file).each_line do |line|
        /^msgid "(.*)"/ =~ line
        if $1 && mappings[$1]
          lines << "msgid \"#{lang_mappings.delete($1)}\""
        else
          lines << line
        end
      end
      puts "Mappings unused in #{po_file}: #{lang_mappings.keys}" unless lang_mappings.empty?
      File.open(po_file, "w") { |f| f.puts(lines) }
    end
  end

  # Use a quote for quote-escaping as CSV errors on the \" with "Missing or stray quote"
  def clean_csv_mapping_file(file)
    data = ''
    File.foreach(file) do |line|
      data += line.gsub('\"', '""')
    end
    data
  end

  def find_theme(theme)
    unless theme
      puts "Usage: Specify an Alaveteli-theme with THEME=[theme directory name]"
      exit(1)
    end
    theme
  end

  def find_mapping_file(file)
    unless file
      puts "Usage: Specify a csv file mapping old to new strings with MAPPING_FILE=[file name]"
      exit(1)
    end
    unless File.exists?(file)
      puts "Error: MAPPING_FILE #{file} not found"
      exit(1)
    end
    file
  end

  def files_to_translate
    files = FileList.new("{app,lib,config,#{locale_path}}/**/*.{rb,erb}") do |fl|
      fl.exclude(/\balaveteli_pro\b/)
    end
    files
  end

  def pro_files_to_translate
    files = FileList.new do |fl|
      fl.include('app/{models,views,helpers,controllers}/alaveteli_pro/**/*.{rb,erb}')
      fl.include('lib/alaveteli_pro/**/*.{rb,erb}')
    end
    files
  end

  def pro_locale_path
    Rails.root.join "locale_alaveteli_pro"
  end

  def theme_files_to_translate(theme)
    Dir.glob("{lib/themes/#{theme}/lib}/**/*.{rb,erb}")
  end

  def theme_locale_path(theme)
    Rails.root.join "lib", "themes", theme, "locale-theme"
  end

end
