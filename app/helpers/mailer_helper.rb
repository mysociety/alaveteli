module MailerHelper
  # Generate a case reference number to differentiate subject lines and/or
  # include in the body of emails.
  #
  # prefix - A String prefix to identify the general case type
  #          (default: 'CASE').
  #
  # Examples:
  #
  #    case_reference
  #    # => "CASE/20231020-DF1I"
  #
  #    case_reference('HELP')
  #    # => "HELP/20231020-QK3C"
  #
  # Returns a String case reference ID.
  def case_reference(prefix = 'CASE')
    "#{prefix}/#{Time.now.strftime('%Y%m%d')}-#{SecureRandom.base36(4).upcase}"
  end

  def contact_from_name_and_email
    "#{AlaveteliConfiguration.contact_name} <#{AlaveteliConfiguration.contact_email}>"
  end

  def pro_contact_from_name_and_email
    "#{AlaveteliConfiguration.pro_contact_name} <#{AlaveteliConfiguration.pro_contact_email}>"
  end
end
