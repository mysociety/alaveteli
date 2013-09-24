namespace :gettext do

  desc 'Rewrite .po files into a consistent msgmerge format'
  task :clean do
    load_gettext

    Dir.glob("locale/*/app.po") do |po_file|
      GetText::msgmerge(po_file, po_file, 'alaveteli', :msgmerge => [:sort_output, :no_location, :no_wrap])
    end
  end

  desc "Update pot/po files for a theme."
  task :find_theme => :environment do
    theme = ENV['THEME']
    unless theme
        puts "Usage: Specify an Alaveteli-theme with THEME=[theme directory name]"
        exit(0)
    end
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

   def theme_files_to_translate(theme)
       Dir.glob("{vendor/plugins/#{theme}/lib}/**/*.{rb,erb}")
   end

   def theme_locale_path(theme)
     File.join(Rails.root, "vendor", "plugins", theme, "locale-theme")
   end

end
