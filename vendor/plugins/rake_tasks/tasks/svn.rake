namespace :svn do
  desc 'Adds new files to subversion'
  task :add do
    `svn status | grep '^\?' | sed -e 's/? *//' | sed -e 's/ /\ /g' | xargs svn add`
  end
  
  desc 'Removes missing files from subversion'
  task :remove do
    `svn status | grep '^\!' | sed -e 's/! *//' | sed -e 's/ /\ /g' | xargs svn remove`
  end
  
  desc 'Deletes unknown files'
  task :delete do
    `svn status | grep '^\?' | sed -e 's/? *//' | sed -e 's/ /\ /g' | xargs rm -Rf`
  end
  
  desc 'Configures svn:ignore properties on log, tmp, db/schema.rb and config/database.yml'
  task :ignore => :environment do 
    ignore :log => '*'
    ignore :tmp => '*'
    ignore :db => ['schema.rb', '*.sqlite3']
    ignore :config => 'database.yml'
  end
  
  desc 'Resolves all svn conflicts by keeping the working file'
  task :conflicts do
    `svn status | grep '^C' | sed -e 's/C *//' | sed -e 's/ /\ /g'`.split("\n").each do |conflict|
      `mv #{conflict}.working #{conflict}`
      `rm #{conflict}.merge-*`
    end
  end
end

private 

def ignore(files)
  files.each_pair do |location, pattern|
    case pattern
      when Array
        pattern.each { |p| ignore(location => p) }
      when String
        remove_versioned_files(location, pattern)
        update_ignore_property(location, pattern)
    end
  end
end

def remove_versioned_files(location, pattern)
  path = File.join(location.to_s, pattern)
  FileUtils.mv(path, "#{path}.tmp") if File.exists? path
  `svn remove '#{path}' --force`
  FileUtils.mv("#{path}.tmp", path) if File.exists? "#{path}.tmp"
end

def update_ignore_property(location, pattern)
  ignored_patterns = `svn propget svn:ignore #{location}`.split(/\s/)
  ignored_patterns << pattern unless ignored_patterns.include? pattern
  `svn propset svn:ignore '#{ignored_patterns.join("\n")}' #{location}`
end