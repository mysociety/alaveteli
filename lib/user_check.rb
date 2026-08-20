require 'json'
require 'net/http'

##
# UserCheck.com integration for UserSpamScorer.
#
# Looks up email domains against the UserCheck API
# (https://www.usercheck.com) to detect disposable domains, relay domains
# and domains with invalid MX records, and registers a scoring method for
# each with UserSpamScorer.
#
# The integration is opt-in: scoring methods are only registered when
# USERCHECK_API_KEY is set in config/general.yml.
#
# Privacy contract: only the email *domain* is ever sent to the API, never
# the local part of the address. Results are cached per domain for
# CACHE_DURATION, so a domain that has already been checked generates no
# further requests. API failures are logged and score nothing, so an outage
# degrades to the static domain list checks.
module UserCheck
  API_BASE_URL = 'https://api.usercheck.com'
  REQUEST_TIMEOUT = 5.seconds
  CACHE_DURATION = 28.days
  SAFE_RESULT = { disposable: false, relay_domain: false }.freeze

  class << self
    attr_writer :api_key

    def api_key
      @api_key ||= AlaveteliConfiguration.usercheck_api_key
    end

    def enabled?
      api_key.present?
    end

    def check_domain(domain)
      return SAFE_RESULT unless enabled?
      return SAFE_RESULT if domain.blank?

      cache_key = "usercheck_domain_#{domain}"
      cached_result = Rails.cache.read(cache_key)
      return cached_result if cached_result

      result = make_api_request(domain)

      if result[:success]
        Rails.cache.write(cache_key, result, expires_in: CACHE_DURATION)
      end

      result
    end

    def register_scoring_methods!
      return unless enabled?

      UserSpamScorer.register_custom_scoring_method(
        :email_domain_is_disposable,
        20,
        proc do |user|
          result = UserCheck.check_domain(user.email_domain)
          result[:success] && result[:disposable]
        end
      )

      UserSpamScorer.register_custom_scoring_method(
        :email_domain_is_relay,
        10,
        proc do |user|
          result = UserCheck.check_domain(user.email_domain)
          result[:success] && result[:relay_domain]
        end
      )

      UserSpamScorer.register_custom_scoring_method(
        :email_domain_invalid_mx,
        5,
        proc do |user|
          result = UserCheck.check_domain(user.email_domain)
          result[:success] && result[:mx_valid] == false
        end
      )
    end

    private

    def make_api_request(domain)
      uri = URI("#{API_BASE_URL}/domain/#{domain}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = REQUEST_TIMEOUT
      http.read_timeout = REQUEST_TIMEOUT

      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{api_key}"

      response = http.request(request)

      case response.code
      when '200'
        data = JSON.parse(response.body)
        {
          success: true,
          disposable: data['disposable'] == true,
          relay_domain: data['relay_domain'] == true,
          mx_valid: data['mx'] == true,
          raw_data: data
        }
      when '401'
        Rails.logger.error('UserCheck API: Invalid API key')
        { success: false, error: 'Invalid API key' }
      when '429'
        Rails.logger.warn('UserCheck API: Rate limit exceeded')
        { success: false, error: 'Rate limit exceeded' }
      else
        Rails.logger.warn(
          "UserCheck API: Unexpected response #{response.code}"
        )
        { success: false, error: "HTTP #{response.code}" }
      end
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.warn("UserCheck API: Timeout: #{e.message}")
      { success: false, error: 'Timeout' }
    rescue JSON::ParserError => e
      Rails.logger.error("UserCheck API: Invalid JSON response: #{e.message}")
      { success: false, error: 'Invalid JSON response' }
    rescue StandardError => e
      Rails.logger.error("UserCheck API: Unexpected error: #{e.message}")
      { success: false, error: e.message }
    end
  end
end
