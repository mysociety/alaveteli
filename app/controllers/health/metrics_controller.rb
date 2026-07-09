module Health
  ##
  # This controller is responsible for providing an overview of system metrics
  # for internal monitoring checks
  #
  class MetricsController < ApplicationController
    skip_before_action :html_response

    layout false

    def index
      @sidekiq_stats = Sidekiq::Stats.new
      @sidekiq_default_queue_latency = Sidekiq::Queue.new.latency
      @queued_index_jobs = Search.queued_jobs_count
      @bot_traffic_metrics = BotTrafficMetrics.snapshot
      @turnstile_enabled = ENV['TURNSTILE_ENABLED'] == 'true'
      @turnstile_configured = ENV['TURNSTILE_SITE_KEY'].present? &&
        ENV['TURNSTILE_SECRET_KEY'].present?
      @verified_bot_token_configured = ENV['FYI_BOT_TOKEN'].present?
    rescue StandardError => e
      Rails.logger.error("Health metrics collection failed: #{e.message}")
      @sidekiq_stats = Struct.new(
        :processed, :workers_size, :enqueued, :retry_size,
        :scheduled_size, :failed, :dead_size
      ).new(0, 0, 0, 0, 0, 0, 0)
      @sidekiq_default_queue_latency = 0
      @queued_index_jobs = 0
      @bot_traffic_metrics = BotTrafficMetrics::EVENTS.to_h do |event|
        [event, 0]
      end
      @turnstile_enabled = false
      @turnstile_configured = false
      @verified_bot_token_configured = false
    end
  end
end
