# models/contact_mailer.rb:
# Sends contact form mails.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/

class ContactMailer < ApplicationMailer

    # Send message to administrator
    def message(name, email, subject, message, logged_in_user, last_request, last_body)
        @from = name + " <" + email + ">"
        @recipients = contact_from_name_and_email
        @subject = subject
        @body = { :message => message,
            :logged_in_user => logged_in_user ,
            :last_request => last_request,
            :last_body => last_body
        }
    end

    # We always set Reply-To when we set Return-Path to be different from From,
    # since some email clients seem to erroneously use the envelope from when
    # they shouldn't, and this might help. (Have had mysterious cases of a
    # reply coming in duplicate from a public body to both From and envelope
    # from)

    # Send message to another user
    def user_message(from_user, recipient_user, from_user_url, subject, message)
        @from = from_user.name_and_email
        # Do not set envelope from address to the from_user, so they can't get
        # someone's email addresses from transitory bounce messages.
        headers 'Return-Path' => blackhole_email, 'Reply-To' => @from
        @recipients = recipient_user.name_and_email
        @subject = subject
        @body = {
            :message => message,
            :from_user => from_user,
            :recipient_user => recipient_user,
            :from_user_url => from_user_url
        }
    end

    # Send message to a user from the administrator
    def from_admin_message(recipient_user, subject, message)
        @from = contact_from_name_and_email
        @recipients = recipient_user.name_and_email
        @subject = subject
        @body = {
            :message => message,
            :from_user => @from,
            :recipient_user => recipient_user,
        }
        bcc Configuration::contact_email
    end

end
