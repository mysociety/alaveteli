# -*- encoding : utf-8 -*-
#
# Public: methods for the gettext rake tasks

module AlaveteliGetText

  module TaskMethods
    require 'rake/file_list'
    require 'gettext/tools/task'

    def find_theme(theme)
      unless theme
        puts "Usage: Specify an Alaveteli-theme with THEME=[theme directory name]"
        exit(1)
      end
      theme
    end

    def clean_dir(dir)
      Dir.glob("#{dir}/*/app.po") do |po_file|
        GetText::Tools::MsgMerge.run("--output", po_file,
                                     "--sort-output",
                                     "--no-location",
                                     "--no-wrap",
                                     "--no-fuzzy-matching",
                                     po_file,
                                     po_file)
      end

      # invoke the remove_fuzzy task as MsgMerge doesn't seem to do this any more
      Rake::Task["gettext:remove_fuzzy"].invoke(dir)
    end

    def files_to_translate
      files = ::Rake::FileList.new("{app,lib,config,#{locale_path}}/**/*.{rb,erb}") do |fl|
        fl.exclude(/\balaveteli_pro\b/)
      end
      files
    end

    def theme_files_to_translate(theme)
      ::Rake::FileList.new("{lib/themes/#{theme}/lib}/**/*.{rb,erb}")
    end

    def pro_files_to_translate
      files = ::Rake::FileList.new do |fl|
        fl.include('app/{models,views,helpers,controllers}/alaveteli_pro/**/*.{rb,erb}')
        fl.include('lib/alaveteli_pro/**/*.{rb,erb}')
      end
      files
    end

    def locale_path
      Rails.root.join "locale"
    end

    def theme_locale_path(theme)
      Rails.root.join "lib", "themes", theme, "locale-theme"
    end

    def pro_locale_path
      Rails.root.join "locale_alaveteli_pro"
    end

    def define_gettext_task(text_domain, locale_path, files_to_translate, version=nil)
      options = Rails.application.config.gettext_i18n_rails.msgmerge
      options ||= %w[--sort-output --no-location --no-wrap]

      # prevent app.po.edit and app.po.timestamp files being created
      ENV["VERSION_CONTROL"] = "off"

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

    # Use a quote for quote-escaping as CSV errors on the \" with "Missing or stray quote"
    def clean_csv_mapping_file(file)
      data = ''
      File.foreach(file) do |line|
        data += line.gsub('\"', '""')
      end
      data
    end

  end

end
