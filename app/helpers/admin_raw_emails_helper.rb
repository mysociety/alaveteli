# -*- encoding : utf-8 -*-
# View helpers for displaying RawEmails in the admin interface
module AdminRawEmailsHelper
  # Public: Format a list of email addresses for display.
  # Wraps each address in a <code> tag and joins the list with a comma.
  #
  # Returns a String
  def address_list(addresses)
    addresses = Array(addresses).compact
    addresses.map { |addr| content_tag :code, addr }.join(', ').html_safe
  end
end
