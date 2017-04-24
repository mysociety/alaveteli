# -*- encoding : utf-8 -*-
namespace :gettext do

  tasks = Rake.application.instance_variable_get '@tasks'
  tasks.delete 'gettext:find'

  desc "Update pot/po files"
  task :find => :environment do
    CLEAN = FileList["locale/*/*~",
                     "locale/*/*.bak"]

    define_gettext_task(text_domain,
                        "locale",
                        files_to_translate)

    quietly do
      Rake::Task["gettext:po:update"].invoke
    end
  end

  desc 'Rewrite .po files into a consistent msgmerge format'
  task :clean => :environment do
    CLEAN = FileList["locale/*/*~", "locale/*/*.bak"]
    clean_dir("locale")
  end

  desc 'Rewrite Alaveteli Pro .po files into a consistent msgmerge format'
  task :clean_alaveteli_pro => :environment do
    CLEAN = FileList["locale_alaveteli_pro/*/*~",
                     "locale_alaveteli_pro/*/*.bak"]
    clean_dir("locale_alaveteli_pro")
  end

  desc "Update pot/po files for a theme."
  task :find_theme => :environment do
    theme = find_theme(ENV['THEME'])
    CLEAN = FileList["#{theme_locale_path(theme)}/*/*~",
                     "#{theme_locale_path(theme)}/*/*.bak"]

    define_gettext_task(text_domain,
                        theme_locale_path(theme),
                        theme_files_to_translate(theme))

    quietly do
      Rake::Task["gettext:po:update"].invoke
    end
  end

  desc "Update pot/po files for Alaveteli Pro."
  task :find_alaveteli_pro => :environment do
    CLEAN = FileList["#{pro_locale_path}/*/*~",
                     "#{pro_locale_path}/*/*.bak"]

    define_gettext_task(text_domain,
                        pro_locale_path,
                        pro_files_to_translate)

    quietly do
      Rake::Task["gettext:po:update"].invoke
    end
  end

  desc 'Rewrite theme .po files into a consistent msgmerge format'
  task :clean_theme => :environment do
    theme = find_theme(ENV['THEME'])
    CLEAN = FileList["#{theme_locale_path(theme)}/*/*~",
                     "#{theme_locale_path(theme)}/*/*.bak"]
    clean_dir(theme_locale_path(theme))
  end

  desc 'Remove fuzzy translations'
  task :remove_fuzzy,[:dir] do |t, args|
    require "alaveteli_gettext/fuzzy_cleaner.rb"
    fuzzy_cleaner = AlaveteliGetText::FuzzyCleaner.new

    dir = args[:dir] || "locale"

    Dir.glob("#{dir}/*/app.po").each do |po_file|
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

  def clean_dir(dir)
    define_gettext_task("alaveteli",
                        dir,
                        Dir.glob("#{dir}/*/app.po"),
                        "alaveteli")

    Dir.glob("#{dir}/*/app.po") do |po_file|
      GetText::Tools::MsgMerge.run("--output", po_file,
                                   "--sort-output",
                                   "--no-location",
                                   "--no-wrap",
                                   "--no-fuzzy-matching",
                                   po_file,
                                   po_file)
    end
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

  def define_gettext_task(text_domain, locale_path, files_to_translate, version=nil)
    options = Rails.application.config.gettext_i18n_rails.msgmerge
    options ||= %w[--sort-output --no-location --no-wrap]

    GetText::Tools::Task.define do |task|
      task.package_name = text_domain
      task.package_version = version || "version 0.0.1"
      task.domain = text_domain
      task.po_base_directory = locale_path
      task.files = files_to_translate
      task.msgmerge_options = options
      task.msgcat_options = options
      task.xgettext_options = options
    end
  end

end
