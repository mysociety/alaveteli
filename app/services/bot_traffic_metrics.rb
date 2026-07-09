# frozen_string_literal: true

class BotTrafficMetrics
  EVENTS = %i[
    bulk_export_requests
    bulk_export_unauthorized
    cache_hits
    cache_misses
    challenge_failed
    challenge_issued
    challenge_passed
    rate_limit_requests
  ].freeze

  def self.increment(event)
    return unless EVENTS.include?(event)

    cache = Rails.cache
    key = cache_key(event)
    cache.increment(key, 1, expires_in: 30.days) || cache.write(
      key, 1, expires_in: 30.days
    )
  rescue StandardError => e
    Rails.logger.error("Bot traffic metric increment failed: #{e.message}")
  end

  def self.snapshot
    EVENTS.to_h { |event| [event, Rails.cache.read(cache_key(event)).to_i] }
  rescue StandardError => e
    Rails.logger.error("Bot traffic metric snapshot failed: #{e.message}")
    EVENTS.to_h { |event| [event, 0] }
  end

  def self.cache_key(event)
    "bot_traffic_metrics:#{event}"
  end
end
