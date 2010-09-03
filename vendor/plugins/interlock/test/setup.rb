
# Setup integration system for the integration suite

Dir.chdir "#{File.dirname(__FILE__)}/integration/app/" do

  `ps awx`.split("\n").grep(/4304[1-3]/).map do |process| 
    system("kill -9 #{process.to_i}")
  end
  
  LOG = "/tmp/memcached.log"

  system "memcached -vv -p 43042 >> #{LOG} 2>&1 &"
  system "memcached -vv -p 43043 >> #{LOG} 2>&1 &"
  
  Dir.chdir "vendor/plugins" do
    system "rm interlock; ln -s ../../../../../ interlock"
  end
  
  system "rake db:create"
  system "rake db:migrate"
  system "rake db:fixtures:load"
end
