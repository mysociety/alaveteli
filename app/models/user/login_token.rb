# Updates the current users login token based on their current password and
# email
module User::LoginToken
  extend ActiveSupport::Concern

  included do
    before_save :update_login_token
  end

  private

  def update_login_token
    update_login_token! if email_changed? || hashed_password_changed?
  end

  def update_login_token!
    self.login_token = Digest::UUID.uuid_v5("User;#{id}", {
      email: email,
      hashed_password: hashed_password
    }.to_s)
  end
end
