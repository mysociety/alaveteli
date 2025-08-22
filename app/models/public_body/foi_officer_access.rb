# Determine whether a user can act as the authority based on the request email
# domain.
module PublicBody::FoiOfficerAccess
  extend ActiveSupport::Concern


  # Does this user have the power of FOI officer for this body?
  def is_foi_officer?(user)
    user_domain = user.email_domain
    our_domain = request_email_domain

    return false if user_domain.nil? || our_domain.nil?

    our_domain == user_domain
  end
end
