namespace :deprecated do
  namespace :convert do
    desc 'Moves .rhtml files to a file with .erb extension for subversion'
    task :erb => :environment do
      Convert::Mover.find(:rhtml).each do |rhtml|
        rhtml.move :erb, :scm => :svn
      end
    end
  end
end