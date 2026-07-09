class Rack::Attack
  class ResilientCacheStore
    def initialize(store)
      @store = store
    end

    def write(*args)
      @store.write(*args)
    rescue StandardError => e
      Rails.logger.error("Rack::Attack Cache Write Error: #{e.message}")
      false
    end

    def read(*args)
      @store.read(*args)
    rescue StandardError => e
      Rails.logger.error("Rack::Attack Cache Read Error: #{e.message}")
      nil
    end

    def increment(*args)
      @store.increment(*args)
    rescue StandardError => e
      Rails.logger.error("Rack::Attack Cache Increment Error: #{e.message}")
      nil
    end

    def fetch(*args, &block)
      @store.fetch(*args, &block)
    rescue StandardError => e
      Rails.logger.error("Rack::Attack Cache Fetch Error: #{e.message}")
      yield if block_given?
    end

    def delete(*args)
      @store.delete(*args)
    rescue StandardError => e
      Rails.logger.error("Rack::Attack Cache Delete Error: #{e.message}")
      false
    end
  end

  def self.high_system_load?
    if defined?(Sidekiq::Queue)
      Sidekiq::Queue.new.size > 100
    else
      false
    end
  rescue StandardError => e
    Rails.logger.error("Rack::Attack system load check failed: #{e.message}")
    false
  end

  # Set up cache store
  unless Rails.env.test?
    redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')
    underlying_store = ActiveSupport::Cache.lookup_store(:redis_cache_store, url: redis_url)
    self.cache.store = ResilientCacheStore.new(underlying_store)
  end

  # Fail2Ban Block for IPs triggering 5 or more 429s in 60 seconds
  blocklist('fail2ban/banning') do |req|
    Fail2Ban.filter("fail2ban-ip:#{req.ip}", maxretry: 5, findtime: 60, bantime: 600) do
      false
    end
  end

  # Subscribe to throttle notifications to count 429 violations
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |name, start, finish, request_id, payload|
    req = payload[:request]
    Fail2Ban.filter("fail2ban-ip:#{req.ip}", maxretry: 5, findtime: 60, bantime: 600) do
      true
    end
  end

  # 1. Verified Bots Tier (100 rpm)
  throttle('req/verified_bot', limit: 100, period: 60) do |req|
    token = req.env['HTTP_X_FYI_BOT_TOKEN']
    if token.present? && token == ENV['FYI_BOT_TOKEN']
      req.ip
    end
  end

  # 2. Anonymous Tier (10 rpm normal, 2 rpm under high system load)
  throttle('req/anonymous', limit: lambda { |req| Rack::Attack.high_system_load? ? 2 : 10 }, period: 60) do |req|
    token = req.env['HTTP_X_FYI_BOT_TOKEN']
    is_verified_bot = token.present? && token == ENV['FYI_BOT_TOKEN']

    unless is_verified_bot
      req.ip
    end
  end

  # Response customizing
  self.throttled_responder = lambda do |env|
    match_data = env['rack.attack.match_data']
    now = match_data[:epoch_time]
    period = match_data[:period]
    limit = match_data[:limit]
    reset_time = period - (now % period)

    headers = {
      'Content-Type' => 'application/json',
      'RateLimit-Limit' => limit.to_s,
      'RateLimit-Remaining' => '0',
      'RateLimit-Reset' => reset_time.to_s,
      'Retry-After' => reset_time.to_s
    }

    [429, headers, [{ error: 'Too Many Requests', retry_after: reset_time }.to_json]]
  end

  self.blocklisted_responder = lambda do |env|
    [403, { 'Content-Type' => 'application/json' }, [{ error: 'Forbidden - IP temporarily banned due to excessive rate limit violations' }.to_json]]
  end
end
