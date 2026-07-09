# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class TurnstileValidator
  def self.validate(token, ip = nil)
    secret_key = ENV['TURNSTILE_SECRET_KEY'] || 'mock-secret-key'
    enabled = ENV['TURNSTILE_ENABLED'] == 'true'

    return true unless enabled
    return false if token.blank?

    uri = URI.parse('https://challenges.cloudflare.com/turnstile/v0/siteverify')
    begin
      response = Net::HTTP.post_form(uri, {
        'secret' => secret_key,
        'response' => token,
        'remoteip' => ip
      })
      result = JSON.parse(response.body) rescue {}
      result['success'] == true
    rescue StandardError => e
      # Fail open on provider outages to avoid locking out legitimate users
      Rails.logger.error("Turnstile validation provider outage error: #{e.message}")
      true
    end
  end
end
