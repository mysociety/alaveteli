# -*- encoding : utf-8 -*-
# models/contact_mailer.rb:
# Sends contact form mails.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class ContactMailer < ApplicationMailer
  include AlaveteliFeatures::Helpers

  # Send message to administrator
  def to_admin_message(name, email, subject, message, logged_in_user, last_request, last_body)
    @message, @logged_in_user, @last_request, @last_body = message, logged_in_user, last_request, last_body

    reply_to_address = MailHandler.address_from_name_and_email(name, email)
    set_reply_to_headers(nil, 'Reply-To' => reply_to_address)

    # From is an address we control so that strict DMARC senders don't get refused
    mail(:from => MailHandler.address_from_name_and_email(name, blackhole_email),
         :to => contact_for_user(@logged_in_user),
         :subject => subject)
  end

  # Send message to another user
  def user_message(from_user, recipient_user, from_user_url, subject, message)
    @message, @from_user, @recipient_user, @from_user_url = message, from_user, recipient_user, from_user_url

    set_reply_to_headers(nil, 'Reply-To' => from_user.name_and_email)

    # From is an address we control so that strict DMARC senders don't get refused
    mail(:from => MailHandler.address_from_name_and_email(from_user.name, blackhole_email),
         :to => recipient_user.name_and_email,
         :subject => subject)
  end

  # Send message to a user from the administrator
  def from_admin_message(recipient_name, recipient_email, subject, message)
    @message = message
    @recipient_name, @recipient_email = recipient_name, recipient_email

    recipient_user = User.find_by_email(recipient_email)

    mail(:from => contact_for_user(recipient_user),
         :to => MailHandler.address_from_name_and_email(@recipient_name, @recipient_email),
         :bcc => AlaveteliConfiguration::contact_email,
         :subject => subject)
  end

  # Send a request to the administrator to add an authority
  def add_public_body(change_request)
    @change_request = change_request

    reply_to_address = MailHandler.address_from_name_and_email(
      @change_request.get_user_name,
      @change_request.get_user_email)
    set_reply_to_headers(nil, 'Reply-To' => reply_to_address)

    # From is an address we control so that strict DMARC senders don't get refused
    mail(:from => MailHandler.address_from_name_and_email(
                    @change_request.get_user_name,
                    blackhole_email
                  ),
         :to => contact_from_name_and_email,
         :subject => _('Add authority - {{public_body_name}}',
                       :public_body_name => @change_request.
                                              get_public_body_name.html_safe))
  end

  # Send a request to the administrator to update an authority email address
  def update_public_body_email(change_request)
    @change_request = change_request

    reply_to_address = MailHandler.address_from_name_and_email(
      @change_request.get_user_name,
      @change_request.get_user_email)
    set_reply_to_headers(nil, 'Reply-To' => reply_to_address)

    # From is an address we control so that strict DMARC senders don't get refused
    mail(:from => MailHandler.address_from_name_and_email(
                    @change_request.get_user_name,
                    blackhole_email
                  ),
         :to => contact_from_name_and_email,
         :subject => _('Update email address - {{public_body_name}}',
                       :public_body_name => @change_request.
                                              get_public_body_name.html_safe))
  end

end
