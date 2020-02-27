# -*- encoding : utf-8 -*-
module MailerHelper
  def contact_from_name_and_email
    "#{AlaveteliConfiguration.contact_name} <#{AlaveteliConfiguration.contact_email}>"
  end

  def pro_contact_from_name_and_email
    "#{AlaveteliConfiguration.pro_contact_name} <#{AlaveteliConfiguration.pro_contact_email}>"
  end
end
