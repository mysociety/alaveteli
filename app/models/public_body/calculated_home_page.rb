# Guess the home page based on the request email domain.
module PublicBody::CalculatedHomePage
  # Guess home page from the request email, or use explicit override, or nil
  # if not known.
  #
  # TODO: PublicBody#calculated_home_page would be a good candidate to cache
  # in an instance variable
  def calculated_home_page
    if home_page && !home_page.empty?
      home_page[URI.regexp(%w(http https))] ? home_page : "https://#{home_page}"
    elsif request_email_domain
      "https://www.#{request_email_domain}"
    end
  end
end
