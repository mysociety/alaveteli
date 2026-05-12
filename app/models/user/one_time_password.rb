# Optional two factor authentication
module User::OneTimePassword
  extend ActiveSupport::Concern

  included do
    has_one_time_password after_column_name: :otp_last_used_at,
                          one_time_backup_codes: true

    attr_accessor :entered_otp_code

    validate :verify_otp_code, if: :otp_enabled_and_required?
    validate :otp_backup_codes_paired_with_timestamp

    # The `before_create` hook in active_model_otp auto-generates backup codes
    # if the `otp_backup_codes` column exists, but it has no awareness of the
    # `otp_backup_codes_generated_at` column, so codes would be persisted
    # without a matching issued-at timestamp. Codes are only meaningful
    # alongside the timestamp, so suppress the auto-generation and let
    # TOTP enrolment populate both columns together.
    before_create -> { self.otp_backup_codes = [] }

    # active_model_otp reads `otp_counter_based` from self in
    # `authenticate_otp`, `otp_code` and `provisioning_uri`, so deriving it
    # from the persisted counter dispatches each user to the right HOTP/TOTP
    # branch without a separate mode column.
    def otp_counter_based # rubocop:disable Naming/PredicateMethod
      otp_counter.present?
    end
  end

  def otp_enabled?
    otp_secret_key.present? && otp_enabled
  end

  def hotp?
    otp_enabled? && otp_counter.present?
  end

  def totp?
    otp_enabled? && otp_counter.nil?
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

  # Backup codes are only meaningful alongside a generated-at timestamp.
  # Writing one without the other would mean e.g. the management page showing
  # "last regenerated never" for a user who has codes.
  # Enforce that they're set or cleared together.
  def otp_backup_codes_paired_with_timestamp
    has_codes = otp_backup_codes.present?
    has_timestamp = otp_backup_codes_generated_at.present?
    return if has_codes == has_timestamp

    errors.add(:otp_backup_codes,
               'must be set together with otp_backup_codes_generated_at')
  end

  def verify_otp_code
    if entered_otp_code.nil? || !authenticate_otp(entered_otp_code)
      msg = _('Invalid one time password')
      errors.add(:otp_code, msg)
      return false
    end

    self.otp_counter += 1 if otp_counter_based
    self.entered_otp_code = nil
  end
end
