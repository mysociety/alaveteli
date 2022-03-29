# Sets the current users login token based on their current password and email
module User::LoginToken
  extend ActiveSupport::Concern

  LOGIN_TOKEN_NAMESPACE = 'b14cba73-a392-4de4-a9ed-06d7f0ced429'

  included do
    before_save :set_login_token
  end

  private

  def set_login_token
    set_login_token! if email_changed? || hashed_password_changed?
  end

  def set_login_token!
    self.login_token = Digest::UUID.uuid_v5(
      LOGIN_TOKEN_NAMESPACE,
      {
        user: id,
        email: email,
        hashed_password: hashed_password
      }.to_s
    )
  end
end
