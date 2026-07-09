module TrafficControl
  extend ActiveSupport::Concern

  included do
    after_action :inject_rate_limit_headers
    after_action :record_cache_metric
  end

  def public_cache_control(record_or_etag, last_modified: nil)
    return unless request.get?

    request.env['bot_traffic.cache_controlled'] = true
    fresh_when(etag: record_or_etag, last_modified: last_modified, public: true)
  end

  private

  def inject_rate_limit_headers
    throttle_data = request.env['rack.attack.throttle_data']
    return unless throttle_data.present?

    name, data = throttle_data.find { |k, v| k.start_with?('req/') }
    return unless data.present?

    limit = data[:limit]
    period = data[:period]
    count = data[:count]
    epoch_time = data[:epoch_time]

    remaining = [limit - count, 0].max
    reset_time = period - (epoch_time % period)

    response.headers['RateLimit-Limit'] = limit.to_s
    response.headers['RateLimit-Remaining'] = remaining.to_s
    response.headers['RateLimit-Reset'] = reset_time.to_s

    if Rack::Attack.high_system_load?
      response.headers['X-Advisory-Status'] = 'degraded'
      response.headers['Retry-After'] = '60'
    end
  end

  def record_cache_metric
    return unless request.env['bot_traffic.cache_controlled']

    event = response.status == 304 ? :cache_hits : :cache_misses
    BotTrafficMetrics.increment(event)
  end
end
