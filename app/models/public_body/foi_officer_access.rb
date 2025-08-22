# Determine whether a user can act as the authority based on the request email
# domain.
module PublicBody::FoiOfficerAccess
  extend ActiveSupport::Concern

  included do
    cattr_accessor :excluded_foi_officer_access_domains, default: %w[
      aol.com
      gmail.com
      googlemail.com
      gmx.com
      hotmail.com
      icloud.com
      live.com
      mac.com
      mail.com
      mail.ru
      me.com
      outlook.com
      protonmail.com
      qq.com
      yahoo.com
      yandex.com
      ymail.com
      zoho.com
    ]
  end

  def foi_officer_domain_excluded?
    excluded_foi_officer_access_domains.include?(request_email_domain)
  end

  # Does this user have the power of FOI officer for this body?
  def is_foi_officer?(user)
    return false if outside_user?(user)
    return true if registered_with_main_foi_address?(user)

    domain_within_authority?(user) && no_restrictions_on_domain?(user)
  end

  private

  def domain_within_authority?(user)
    user_domain = user.email_domain
    our_domain = request_email_domain

    return false if user_domain.nil? || our_domain.nil?

    our_domain == user_domain
  end

  def no_restrictions_on_domain?(user)
    !excluded_foi_officer_access_domains.include?(user.email_domain)
  end

  def outside_user?(user)
    !domain_within_authority?(user)
  end

  def registered_with_main_foi_address?(user)
    user.email.downcase == request_email.downcase
  end
end
