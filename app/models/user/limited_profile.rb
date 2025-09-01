module User::LimitedProfile
  extend ActiveSupport::Concern

  class_methods do
    # return an array of limited users i.e. untrusted users without any requests
    # or classifications
    def limited_profile
      roles = Role.arel_table
      user_roles = Arel::Table.new(:users_roles)
      user_admin_roles_exists = user_roles.project(1).
        join(roles).on(user_roles[:role_id].eq(roles[:id])).
        where(user_roles[:user_id].eq(User.arel_table[:id])).
        where(roles[:name].in(%w[admin pro_admin])).
        exists

      User.
        where.not(email: internal_admin_user.email).
        where(confirmed_not_spam: false).
        where(info_requests_count: 0).
        where(status_update_count: 0).
        where.not(user_admin_roles_exists)
    end
  end

  def limited_profile?
    self != User.internal_admin_user &&
      !is_admin? && !is_pro_admin? &&
      !confirmed_not_spam? &&
      info_requests_count.zero? &&
      status_update_count.zero?
  end
end
