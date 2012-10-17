module MailerHelper
    def contact_from_name_and_email
        "#{Configuration::contact_name} <#{Configuration::contact_email}>"
    end
end
