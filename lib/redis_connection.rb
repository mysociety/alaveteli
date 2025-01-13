require File.expand_path('../config/load_env.rb', __dir__)
require 'redis-client'

##
# Module to parse Redis ENV variables into usable configuration for Sidekiq and
# ActiveJob::Uniqueness gems.
#
module RedisConnection
  def self.instance
    Redis.new(configuration)
  end

  def self.client
    if configuration.key?(:sentinels)
      RedisClient.sentinel(**configuration).new_client
    else
      RedisClient.config(**configuration).new_client
    end
  end

  def self.configuration
    { url: ENV['REDIS_URL'], password: ENV['REDIS_PASSWORD'] }.
      merge(sentinel_configuration)
  end

  def self.sentinel_configuration
    return {} unless ENV['REDIS_SENTINELS']

    sentinels = ENV['REDIS_SENTINELS'].split(',').map do |ip_and_port|
      ip, port = ip_and_port.split(/:(\d+)$/)
      ip = Regexp.last_match[1] if ip =~ /\[(.*?)\]/
      { host: ip, port: port&.to_i || 26_379 }
    end

    { sentinels: sentinels, role: :master }
  end
end
