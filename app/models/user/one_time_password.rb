# Optional two factor authentication
module User::OneTimePassword
  extend ActiveSupport::Concern

  included do
    has_one_time_password after_column_name: :otp_last_used_at

    # otp_backup_codes is a single encrypted text column holding a JSON array of
    # the plaintext codes. active_model_otp expects an array, so serialize back
    # to one and default to an empty array when unset.
    serialize :otp_backup_codes, coder: JSON, type: Array
    attribute :otp_backup_codes, default: []
    encrypts :otp_backup_codes

    attr_accessor :entered_otp_code

    scope :without_two_factor, -> { where(otp_enabled: false) }
    scope :with_hotp, -> { where(otp_enabled: true).where.not(otp_counter: nil) }
    scope :with_totp, -> { where(otp_enabled: true, otp_counter: nil) }

    validate :verify_otp_code, if: :otp_enabled_and_required?
    validate :otp_backup_codes_paired_with_timestamp

    # active_model_otp reads `otp_counter_based` from self in
    # `authenticate_otp`, `otp_code` and `provisioning_uri`, so deriving it
    # from the persisted counter dispatches each user to the right HOTP/TOTP
    # branch without a separate mode column.
    def otp_counter_based # rubocop:disable Naming/PredicateMethod
      otp_counter.present?
    end

    # Override the gem's `authenticate_otp` for two reasons:
    #
    # 1. The gem checks backup codes before the primary factor. Try the primary
    #    factor first so a valid authenticator code never spends one of the
    #    user's single-use backup codes, only falling back to backup codes when
    #    it fails.
    #
    # 2. active_model_otp's `authenticate_totp` persists the anti-replay
    #    timestamp via `update(otp_last_used_at: ts)`. When this runs inside a
    #    save (e.g. PasswordChangesController#update with require_otp), that
    #    nested update re-runs validations and re-enters `verify_otp_code`
    #    with the same code. `otp_last_used_at` is now set, so ROTP rejects it
    #    as replayed and the outer save fails despite a valid code. Flag the
    #    in-progress authentication so the re-entrant validation skips
    #    re-verifying.
    #
    # The override must live here (on the class) rather than in the module
    # body so `super` reaches the gem's method, which is included into the
    # class by `has_one_time_password` above.
    def authenticate_otp(code, options = {})
      return false if code.blank?

      @authenticating_otp = true
      super || authenticate_backup_code(code)
    ensure
      @authenticating_otp = false
    end

    # active_model_otp's `before_create` hook would generate backup codes for
    # every new user. Switch the gem's machinery off and replace it with the
    # implementation below: `otp_regenerate_backup_codes` issues codes only when
    # called explicitly, and `authenticate_otp` restores backup codes as a
    # fallback to the primary factor.
    def backup_codes_enabled?
      false
    end

    # Replaces the gem's generator. Returns the codes, the only point at which
    # they're shown to the user. They're persisted encrypted at rest via the
    # `encrypts :otp_backup_codes` declaration. Callers are responsible for
    # saving.
    def otp_regenerate_backup_codes
      codes = Array.new(self.class.otp_backup_codes_count) do
        format("%0#{otp_digits}d", SecureRandom.random_number(10**otp_digits))
      end
      self.otp_backup_codes = codes
      self.otp_backup_codes_generated_at = Time.current
      codes
    end

    def authenticate_backup_code(code) # rubocop:disable Naming/PredicateMethod
      return false unless otp_backup_codes.include?(code)

      remaining = otp_backup_codes - [code]
      self.otp_backup_codes = remaining
      update_column(:otp_backup_codes, remaining) if persisted?
      true
    end
    private :authenticate_backup_code
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

  # Persist `secret` as the user's otp_secret_key and flip the user to TOTP.
  # No verification, so callers (e.g. OtpEnrolment) are responsible for proving
  # the user holds the secret before invoking this.
  def enable_totp(secret:)
    self.otp_secret_key = secret
    self.otp_counter = nil
    self.otp_enabled = true
    self.otp_enabled_at = Time.zone.now
    save
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

  # Backup codes are only meaningful alongside a generated-at timestamp,
  # codes without one would mean e.g. the management page showing "last
  # regenerated never" for a user who has codes. The reverse, a timestamp
  # with no codes, is a legitimate state once every issued code has been
  # consumed.
  def otp_backup_codes_paired_with_timestamp
    return if otp_backup_codes.blank? ||
              otp_backup_codes_generated_at.present?

    errors.add(:otp_backup_codes,
               'must be set together with otp_backup_codes_generated_at')
  end

  def verify_otp_code
    return if @authenticating_otp

    if entered_otp_code.nil? || !authenticate_otp(entered_otp_code)
      msg = _('Invalid one time password')
      errors.add(:otp_code, msg)
      return false
    end

    self.otp_counter += 1 if otp_counter_based
    self.entered_otp_code = nil
  end
end
