# Optional two factor authentication
module User::OneTimePassword
  extend ActiveSupport::Concern

  included do
    has_one_time_password counter_based: true

    attr_accessor :entered_otp_code

    validate :verify_otp_code, if: :otp_enabled_and_required?
  end

  def otp_enabled?
    (otp_secret_key && otp_counter && otp_enabled) ? true : false
  end

  def enable_otp
    otp_regenerate_secret
    otp_regenerate_counter
    self.otp_enabled = true
  end

  def disable_otp
    self.otp_enabled = false
    self.require_otp = false
    true
  end

  def require_otp?
    @require_otp = false if @require_otp.nil?
    @require_otp
  end

  def require_otp=(value)
    @require_otp = value ? true : false
  end

  private

  def otp_enabled_and_required?
    otp_enabled? && require_otp?
  end

  def verify_otp_code
    if entered_otp_code.nil? || !authenticate_otp(entered_otp_code)
      msg = _('Invalid one time password')
      errors.add(:otp_code, msg)
      return false
    end

    self.otp_counter += 1
    self.entered_otp_code = nil
  end
end
