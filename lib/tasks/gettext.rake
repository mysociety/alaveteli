# -*- encoding : utf-8 -*-
namespace :gettext do
  def msgmerge(*files)
    destination = files.first
    options = %w[--sort-output --no-location --no-wrap --no-obsolete-entries]

    output = Tempfile.new(destination)

    GetText::Tools::MsgMerge.run(*options, '--output', output.path, *files)
    content = output.read
    content.sub!(/(Project-Id-Version\:).*$/, '\\1 alaveteli\\n"')
    File.open(destination, 'w') { |file| file.write(content) }

    output.close!
  end

  def clean(root:)
    Dir.glob("#{root}/*/#{text_domain}.po") do |po_file|
      # merge PO file with themselves - using msgmerge options above to clean
      msgmerge(po_file, po_file)
    end
  end

  desc 'Rewrite .po files into a consistent msgmerge format'
  task :clean do
    clean(root: locale_path)
  end

  desc 'Rewrite Alaveteli Pro .po files into a consistent msgmerge format'
  task :clean_alaveteli_pro do
    clean(root: pro_locale_path)
  end

  desc 'Rewrite theme .po files into a consistent msgmerge format'
  task :clean_theme do
    theme = find_theme(ENV['THEME'])
    clean(root: theme_locale_path(theme))
  end

  def xgettext(pot_file, *files)
    output = Tempfile.new(pot_file)
    output_path = output.path

    # find new strings and write to temp file
    GetText::Tools::XGetText.run(
      '--add-comments=TRANSLATORS', '--output', output_path, *files
    )

    # merge new string temp file with POT file
    msgmerge(pot_file, output_path)

    output.close!
  end

  def find(files:, root:)
    pot_file = File.join(root, "#{text_domain}.pot")

    # extract new strings from files and update POT file
    xgettext(pot_file, *files)

    Dir.glob("#{root}/*/#{text_domain}.po") do |po_file|
      # merge POT file with localised PO files
      msgmerge(po_file, pot_file)
    end
  end

  Rake::Task['find'].clear
  desc "Update pot/po files."
  task :find => :environment do
    find(files: files_to_translate, root: locale_path)
  end

  desc "Update pot/po files for a theme."
  task :find_theme => :environment do
    theme = find_theme(ENV['THEME'])
    find(files: theme_files_to_translate(theme), root: theme_locale_path(theme))
  end

  desc "Update pot/po files for Alaveteli Pro."
  task :find_alaveteli_pro => :environment do
    find(files: pro_files_to_translate, root: pro_locale_path)
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

  desc 'Remove fuzzy translations for Alaveteli Pro'
  task :remove_fuzzy_alaveteli_pro do
    require "alaveteli_gettext/fuzzy_cleaner.rb"
    fuzzy_cleaner = AlaveteliGetText::FuzzyCleaner.new

    Dir.glob("locale_alaveteli_pro/**/app.po").each do |po_file|
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
    unless File.exist?(file)
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
