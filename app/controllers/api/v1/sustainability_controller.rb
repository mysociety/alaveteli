module Api
  module V1
    class SustainabilityController < ApplicationController
      skip_before_action :html_response

      def rate_limit
        rule = limiter.rule
        records = limiter.records(request.remote_ip)
        active_records = rule.records_in_window(records)
        remaining = [rule.count - active_records.count, 0].max
        reset = reset_in_seconds(rule, active_records)

        response.headers['Cache-Control'] = 'no-store'
        response.headers['RateLimit-Limit'] = rule.count.to_s
        response.headers['RateLimit-Remaining'] = remaining.to_s
        response.headers['RateLimit-Reset'] = reset.to_s

        render json: {
          version: 1,
          policy: rule.name,
          limit: rule.count,
          remaining: remaining,
          reset_in_seconds: reset
        }
      rescue StandardError => exception
        Rails.logger.warn("Sustainability rate-limit endpoint unavailable: #{exception.class}")
        render json: { error: 'rate_limit_unavailable' }, status: :service_unavailable
      end

      private

      def limiter
        @limiter ||= AlaveteliRateLimiter::IPRateLimiter.new(:request)
      end

      def reset_in_seconds(rule, records)
        oldest = records.min
        return 0 unless oldest

        expiry = oldest + rule.window.value.send(rule.window.unit)
        [expiry - Time.current, 0].max.to_i
      end
    end
  end
end
