
require 'echoe'

Echoe.new("interlock") do |p|
  p.project = "fauna"
  p.summary = "A Rails plugin for maintainable and high-efficiency caching."
  p.url = "http://blog.evanweaver.com/files/doc/fauna/interlock/"  
  p.docs_host = "blog.evanweaver.com:~/www/bax/public/files/doc/"  
  p.test_pattern = ["test/integration/*.rb", "test/unit/*.rb"]
  p.rdoc_pattern = ["README", "CHANGELOG", "TODO", "LICENSE", "lib/interlock/lock.rb", "lib/interlock/interlock.rb", "lib/interlock/action_controller.rb", "lib/interlock/active_record.rb", "lib/interlock/finders.rb", "lib/interlock/action_view.rb", "lib/interlock/config.rb"]
  p.clean_pattern += ['test/integration/app/coverage', 'test/integration/app/db/schema.rb',
                      'test/integration/app/vendor/plugins/interlock']
end

desc "Run all the tests in production and development mode both"
task "test_all" do  
  ['memcache-client', 'memcached'].each do |client|
    ENV['CLIENT'] = client
    ['false', 'true'].each do |finder|
      ENV['FINDERS'] = finder    
      ['false', 'true'].each do |env|
        ENV['PRODUCTION'] = env
        mode = env == 'false' ? "Development" : "Production"
        STDERR.puts "#{'='*80}\n#{mode} mode, #{client}, finders #{finder}\n#{'='*80}"
        system("rake test:multi_rails:all")
      end
    end
  end
end

task "tail" do
  log = "test/integration/app/log/development.log"
  system("touch #{log} && tail -f #{log} | grep interlock")
end