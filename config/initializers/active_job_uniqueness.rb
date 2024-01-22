require 'redis_connection'

ActiveJob::Uniqueness.configure do |config|
  config.redlock_servers = [RedisConnection.instance]
end
