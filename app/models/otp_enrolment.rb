# A pending TOTP enrolment — the candidate secret is not yet persisted.
class OtpEnrolment
  include ActiveModel::Model

  attr_accessor :user, :secret, :otp_code

  validate :code_matches_secret

  def save
    return false unless valid?

    user.enable_totp(secret: secret)
  end

  def provisioning_uri
    ROTP::TOTP.new(secret, issuer: AlaveteliConfiguration.site_name).
      provisioning_uri(user.email)
  end

  private

  def code_matches_secret
    return if ROTP::TOTP.new(secret).verify(otp_code.to_s)

    errors.add(:otp_code, _('That code did not match. Please try again.'))
  end
end
