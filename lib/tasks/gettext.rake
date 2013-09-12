namespace :gettext do

  desc 'Rewrite .po files into a consistent msgmerge format'
  task :clean do
    load_gettext

    Dir.glob("locale/*/app.po") do |po_file|
      GetText::msgmerge(po_file, po_file, 'alaveteli', :msgmerge => [:sort_output, :no_location, :no_wrap])
    end
  end


end
