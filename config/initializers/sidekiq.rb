require File.expand_path('../load_env.rb', __dir__)

def redis_config
  { url: ENV['REDIS_URL'], password: ENV['REDIS_PASSWORD'] }.
    merge(redis_sentinel_config)
end

def redis_sentinel_config
  return {} unless ENV['REDIS_SENTINELS']

  sentinels = ENV['REDIS_SENTINELS'].split(',').map do |ip_and_port|
    ip, port = ip_and_port.split(/:(\d+)$/)
    ip = Regexp.last_match[1] if ip =~ /\[(.*?)\]/
    { host: ip, port: port&.to_i || 26_379 }
  end

  { sentinels: sentinels, role: :master }
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

if AlaveteliConfiguration.background_jobs == 'embedded' &&
    defined?(PhusionPassenger)

  embedded = Sidekiq.configure_embed do |config|
    config.concurrency = 1
  end

  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    embedded&.run if forked
  end

  PhusionPassenger.on_event(:stopping_worker_process) do
    embedded&.stop
  end
end
