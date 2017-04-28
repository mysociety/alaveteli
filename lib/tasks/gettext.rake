# -*- encoding : utf-8 -*-

require "alaveteli_gettext/task_methods"

namespace :gettext do
  include AlaveteliGetText::TaskMethods

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

    # prevent app.po.edit and app.po.timestamp files being created
    ENV["VERSION_CONTROL"] = "off"

    define_gettext_task(text_domain,
                        pro_locale_path,
                        pro_files_to_translate)

    quietly do
      Rake::Task["gettext:po:update"].invoke
    end
  end

  desc 'Rewrite .po files into a consistent msgmerge format'
  task :clean => :environment do
    CLEAN = FileList["locale/*/*~", "locale/*/*.bak"]
    clean_dir("locale")
  end

  desc 'Rewrite theme .po files into a consistent msgmerge format'
  task :clean_theme => :environment do
    theme = find_theme(ENV['THEME'])
    CLEAN = FileList["#{theme_locale_path(theme)}/*/*~",
                     "#{theme_locale_path(theme)}/*/*.bak"]
    clean_dir(theme_locale_path(theme))
  end

  desc 'Rewrite Alaveteli Pro .po files into a consistent msgmerge format'
  task :clean_alaveteli_pro => :environment do
    CLEAN = FileList["locale_alaveteli_pro/*/*~",
                     "locale_alaveteli_pro/*/*.bak"]
    clean_dir("locale_alaveteli_pro")
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

end
