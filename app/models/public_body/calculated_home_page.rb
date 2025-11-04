# Guess the home page based on the request email domain.
module PublicBody::CalculatedHomePage
  extend ActiveSupport::Concern

  class_methods do
    def excluded_calculated_home_page_domains
      @excluded_calculated_home_page_domains ||= Domains.webmail_providers
    end

    def excluded_calculated_home_page_domains=(domains)
      @excluded_calculated_home_page_domains = domains
    end
  end

  def calculated_home_page
    @calculated_home_page ||= calculated_home_page!
  end

  private

  # Ensure known home page has a full URL or guess if not known.
  def calculated_home_page!
    ensure_home_page_protocol || guess_home_page
  end

  # Ensure the home page has the HTTP protocol at the start of the URL
  def ensure_home_page_protocol
    return unless home_page.present?

    home_page[URI.regexp(%w(http https))] ? home_page : "https://#{home_page}"
  end

  # Guess the home page from the request address email domain.
  def guess_home_page
    return unless request_email_domain
    return if excluded_calculated_home_page_domain?(request_email_domain)

    "https://www.#{request_email_domain}"
  end

  def excluded_calculated_home_page_domain?(domain)
    self.class.excluded_calculated_home_page_domains.include?(domain)
  end
end
