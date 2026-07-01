# Admin-only summary of 2FA enrolment state across the user base.
class Admin::TwoFactorController < AdminController
  def show
    @all_counts = counts_for(User)
    @admin_counts = counts_for(User.with_role(:admin))
    @hotp_users = User.with_hotp.
      order(User.arel_table[:last_sign_in_at].desc.nulls_last)
  end

  private

  def counts_for(scope)
    {
      total: scope.count,
      none: scope.without_two_factor.count,
      hotp: scope.with_hotp.count,
      totp: scope.with_totp.count
    }
  end
end
