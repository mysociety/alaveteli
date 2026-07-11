module Api
  module V1
    class SustainabilityController < ApplicationController
      skip_before_action :html_response

      def rate_limit
        client_ip = normalized_client_ip
        unless client_ip
          response.headers['Cache-Control'] = 'no-store'
          return render json: { error: 'invalid_client_address' }, status: :bad_request
        end

        rule = limiter.rule
        records = limiter.records(client_ip)
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
        response.headers['Cache-Control'] = 'no-store'
        render json: { error: 'rate_limit_unavailable' }, status: :service_unavailable
      end

      private

      def limiter
        @limiter ||= AlaveteliRateLimiter::IPRateLimiter.new(:request)
      end

      def normalized_client_ip
        raw_ip = request.remote_ip.to_s
        valid_ip = [
          IPAddr::RE_IPV4ADDRLIKE,
          IPAddr::RE_IPV6ADDRLIKE_FULL,
          IPAddr::RE_IPV6ADDRLIKE_COMPRESSED
        ].any? { |pattern| pattern.match?(raw_ip) }
        return unless valid_ip

        IPAddr.new(raw_ip).to_s
      rescue IPAddr::InvalidAddressError, ActionDispatch::RemoteIp::IpSpoofAttackError
        nil
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
