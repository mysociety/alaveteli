# -*- encoding : utf-8 -*-
module MailerHelper
    def contact_from_name_and_email
        "#{AlaveteliConfiguration::contact_name} <#{AlaveteliConfiguration::contact_email}>"
    end
end
