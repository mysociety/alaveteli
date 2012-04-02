namespace :gettext do

  desc "Update pot file only, without fuzzy guesses (these are done by Transifex)"
  task :findpot => :environment do
    load_gettext
    $LOAD_PATH << File.join(File.dirname(__FILE__),'..','..','lib')
    require 'gettext_i18n_rails/haml_parser'
    files = files_to_translate

    #write found messages to tmp.pot
    temp_pot = "tmp.pot"
    GetText::rgettext(files, temp_pot)

    #merge tmp.pot and existing pot
    FileUtils.mkdir_p('locale')
    GetText::msgmerge("locale/app.pot", temp_pot, "alaveteli",  :po_root => 'locale', :msgmerge=>[ :no_wrap, :sort_output ]) 
    Dir.glob("locale/*/app.po") do |po_file|
      GetText::msgmerge(po_file, temp_pot, "alaveteli", :po_root => 'locale', :msgmerge=>[ :no_wrap, :sort_output ]) 
    end
    File.delete(temp_pot)
  end 

  def files_to_translate
    Dir.glob("{app,lib,config,locale}/**/*.{rb,erb,haml,rhtml}")
  end
end
