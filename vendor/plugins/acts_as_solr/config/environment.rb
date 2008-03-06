ENV['RAILS_ENV']  = (ENV['RAILS_ENV'] || 'development').dup 
SOLR_PATH = "#{File.dirname(File.expand_path(__FILE__))}/../solr" unless defined? SOLR_PATH

# XXX hacky stuff to read the port from the main config file
RAILS_SOLR_CONFIG="#{SOLR_PATH}/../../../../config/solr.yml"
rails_solr_config = YAML.load(File.read(RAILS_SOLR_CONFIG))
rails_solr_config_read = rails_solr_config[ENV['RAILS_ENV']]
raise "no config in solr.yml for " + ENV['RAILS_ENV'] if rails_solr_config_read.nil?
rails_solr_url = rails_solr_config_read['url']
rails_solr_port = rails_solr_url.match(/http:\/\/localhost:(\d+)\/solr/)[1]
SOLR_PORT = rails_solr_port.to_i

unless defined? SOLR_PORT
  SOLR_PORT = ENV['PORT'] || case ENV['RAILS_ENV']
              when 'test' then 8981
              when 'production' then 8983
              else 8982
              end
end

if ENV['RAILS_ENV'] == 'test'
  DB = (ENV['DB'] ? ENV['DB'] : 'mysql') unless defined? DB
  MYSQL_USER = (ENV['MYSQL_USER'].nil? ? 'root' : ENV['MYSQL_USER']) unless defined? MYSQL_USER
  require File.join(File.dirname(File.expand_path(__FILE__)), '..', 'test', 'db', 'connections', DB, 'connection.rb')
end
