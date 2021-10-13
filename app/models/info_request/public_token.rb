##
# Methods for enabling and disabling InfoRequest public tokens
#
module InfoRequest::PublicToken
  extend ActiveSupport::Concern

  def enable_public_token!
    update(public_token: Digest::UUID.uuid_v4)
  end

  def disable_public_token!
    update(public_token: nil)
  end
end
