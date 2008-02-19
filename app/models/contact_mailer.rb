# models/contact_mailer.rb:
# Sends contact form mails.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: contact_mailer.rb,v 1.1 2008-02-19 17:41:58 francis Exp $

class ContactMailer < ApplicationMailer
 
    def message(name, email, subject, message, request_details)
        @from = name + " <" + email + ">"
        @recipients = contact_from_name_and_email
        @subject = subject
        @body = { :message => message,
            :request_details => "IP " + request_details 
        }
    end

end
