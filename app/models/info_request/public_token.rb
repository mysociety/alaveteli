##
# Methods for enabling and disabling InfoRequest public tokens
#
module InfoRequest::PublicToken
  extend ActiveSupport::Concern

  def enable_public_token!
    token = Digest::UUID.uuid_v4
    update(public_token: token)
    log_event('public_token', token: token, shared: true)
  end

  def disable_public_token!
    update(public_token: nil)
    log_event('public_token', token: nil, shared: false)
  end
end
