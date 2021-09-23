module AuthenicationHelpers
  def sign_in(user)
    session[:user_id] = user&.id
    session[:user_login_token] = user&.login_token
  end
end

RSpec.configure do |config|
  config.include AuthenicationHelpers, type: :controller
end
