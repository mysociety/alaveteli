# The "internal admin" is a special user for internal use.
module User::InternalAdmin
  extend ActiveSupport::Concern

  class_methods do
    def internal_admin_user
      user = find_by(email: AlaveteliConfiguration.contact_email)
      return user if user

      password = PostRedirect.generate_random_token

      create!(
        name: 'Internal admin user',
        email: AlaveteliConfiguration.contact_email,
        password: password,
        password_confirmation: password
      )
    end
  end
end
