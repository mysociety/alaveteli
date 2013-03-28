# models/contact_mailer.rb:
# Sends contact form mails.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class ContactMailer < ApplicationMailer
    # Send message to administrator
    def to_admin_message(name, email, subject, message, logged_in_user, last_request, last_body)
        @message, @logged_in_user, @last_request, @last_body = message, logged_in_user, last_request, last_body

        mail(:from => "#{name} <#{email}>",
             :to => contact_from_name_and_email,
             :subject => subject)
    end

    # We always set Reply-To when we set Return-Path to be different from From,
    # since some email clients seem to erroneously use the envelope from when
    # they shouldn't, and this might help. (Have had mysterious cases of a
    # reply coming in duplicate from a public body to both From and envelope
    # from)

    # Send message to another user
    def user_message(from_user, recipient_user, from_user_url, subject, message)
        @message, @from_user, @recipient_user, @from_user_url = message, from_user, recipient_user, from_user_url

        # Do not set envelope from address to the from_user, so they can't get
        # someone's email addresses from transitory bounce messages.
        headers('Return-Path' => blackhole_email, 'Reply-To' => from_user.name_and_email)

        mail(:from => from_user.name_and_email,
             :to => recipient_user.name_and_email,
             :subject => subject)
    end

    # Send message to a user from the administrator
    def from_admin_message(recipient_user, subject, message)
        @message, @from_user, @recipient_user = message, contact_from_name_and_email, recipient_user

        mail(:from => contact_from_name_and_email,
             :to => recipient_user.name_and_email,
             :bcc => AlaveteliConfiguration::contact_email,
             :subject => subject)
    end
end
