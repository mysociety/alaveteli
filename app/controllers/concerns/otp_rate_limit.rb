# Shared rate limiting for the one time password challenges spread across the
# sign-in, password change, disable and backup-code controllers. Each verifies
# a code with `authenticate_otp`, so without a rate limit each one is
# brute-forceable.
module OtpRateLimit
  extend ActiveSupport::Concern

  MAX_ATTEMPTS = 5
  WINDOW = 1.minute

  # Class methods added to the including controller.
  module ClassMethods
    def limit_otp_attempts(by:, template:, **options)
      rate_limit to: MAX_ATTEMPTS, within: WINDOW, by: by,
                 with: -> { render_otp_rate_limited(template) }, **options
    end
  end

  private

  def render_otp_rate_limited(template)
    flash.now[:error] =
      _('Too many attempts. Please wait a minute and try again.')
    render template, status: :too_many_requests
  end
end
