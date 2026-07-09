# frozen_string_literal: true

module TurnstileChallenge
  extend ActiveSupport::Concern

  included do
    before_action :enforce_turnstile_challenge, if: :should_challenge_request?
  end

  private

  def should_challenge_request?
    return false unless ENV['TURNSTILE_ENABLED'] == 'true'
    # Challenge anonymous requests when throttle data is recorded and session is unverified
    request.env['rack.attack.throttle_data'].present? && session[:turnstile_verified].nil?
  end

  def enforce_turnstile_challenge
    return if verified_bot_request?

    if request.post? && params[:cf_turnstile_response].present?
      if TurnstileValidator.validate(params[:cf_turnstile_response], request.remote_ip)
        session[:turnstile_verified] = true
        return
      else
        flash[:error] = "Verification failed. Please try again."
      end
    end

    render html: challenge_html, layout: false
  end

  def verified_bot_request?
    token = request.headers['X-FYI-Bot-Token']
    token.present? && token == ENV['FYI_BOT_TOKEN']
  end

  def challenge_html
    site_key = ENV['TURNSTILE_SITE_KEY'] || 'mock-site-key'
    <<-HTML.html_safe
      <!DOCTYPE html>
      <html>
      <head>
        <title>Security Verification</title>
        <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
        <style>
          body { font-family: sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #f7f9fa; margin: 0; }
          .container { text-align: center; padding: 40px; background: white; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
          h1 { font-size: 24px; color: #1a1a1a; margin-bottom: 10px; }
          p { color: #666; margin-bottom: 24px; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>Security Verification</h1>
          <p>Please complete this quick challenge to access the site.</p>
          <form method="POST">
            <input type="hidden" name="authenticity_token" value="#{form_authenticity_token rescue ''}">
            <div class="cf-turnstile" data-sitekey="#{site_key}"></div>
            <br/>
            <button type="submit" style="padding: 10px 20px; font-size: 16px; border: none; background: #007bff; color: white; border-radius: 4px; cursor: pointer;">Verify</button>
          </form>
        </div>
      </body>
      </html>
    HTML
  end
end
