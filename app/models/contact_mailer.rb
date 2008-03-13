# models/contact_mailer.rb:
# Sends contact form mails.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: contact_mailer.rb,v 1.5 2008-03-13 12:33:40 francis Exp $

class ContactMailer < ApplicationMailer

    # Send message to administrator
    def message(name, email, subject, message, request_details)
        @from = name + " <" + email + ">"
        @recipients = contact_from_name_and_email
        @subject = subject
        @body = { :message => message,
            :request_details => request_details 
        }
    end

    # Send message to another user
    def user_message(from_user, recipient_user, from_user_url, subject, message)
        @from = from_user.name_and_email
        # Do not set envelope from address to the from_user, so they can't get
        # someone's email addresses from transitory bounce messages.
        headers 'Sender' => contact_from_name_and_email,  # XXX perhaps change to being a black hole
                'Reply-To' => @from
        @recipients = recipient_user.name_and_email
        @subject = subject
        @body = { 
            :message => message,
            :from_user => from_user,
            :recipient_user => recipient_user,
            :from_user_url => from_user_url
        }
    end

end
