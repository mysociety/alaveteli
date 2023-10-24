require 'redis_connection'

Sidekiq.configure_client do |config|
  config.redis = RedisConnection.configuration
end

Sidekiq.configure_server do |config|
  config.redis = RedisConnection.configuration
end
