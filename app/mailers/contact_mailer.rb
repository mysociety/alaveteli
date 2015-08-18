# -*- encoding : utf-8 -*-
# models/contact_mailer.rb:
# Sends contact form mails.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class ContactMailer < ApplicationMailer
  # Send message to administrator
  def to_admin_message(name, email, subject, message, logged_in_user, last_request, last_body)
    @message, @logged_in_user, @last_request, @last_body = message, logged_in_user, last_request, last_body

    # Return path is an address we control so that SPF checks are done on it.
    headers('Return-Path' => blackhole_email, 'Reply-To' => MailHandler.address_from_name_and_email(name, email))

    mail(:from => MailHandler.address_from_name_and_email(name, email),
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
  def from_admin_message(recipient_name, recipient_email, subject, message)
    @message, @from_user = message, contact_from_name_and_email
    @recipient_name, @recipient_email = recipient_name, recipient_email
    mail(:from => contact_from_name_and_email,
         :to => MailHandler.address_from_name_and_email(@recipient_name, @recipient_email),
         :bcc => AlaveteliConfiguration::contact_email,
         :subject => subject)
  end

  # Send a request to the administrator to add an authority
  def add_public_body(change_request)
    @change_request = change_request
    mail(:from => MailHandler.address_from_name_and_email(@change_request.get_user_name, @change_request.get_user_email),
         :to => contact_from_name_and_email,
         :subject => _('Add authority - {{public_body_name}}',
                       :public_body_name => @change_request.get_public_body_name))
  end

  # Send a request to the administrator to update an authority email address
  def update_public_body_email(change_request)
    @change_request = change_request
    mail(:from => MailHandler.address_from_name_and_email(@change_request.get_user_name, @change_request.get_user_email),
         :to => contact_from_name_and_email,
         :subject => _('Update email address - {{public_body_name}}',
                       :public_body_name => @change_request.get_public_body_name))
  end

end
