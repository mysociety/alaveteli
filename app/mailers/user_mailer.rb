# -*- encoding : utf-8 -*-
# models/user_mailer.rb:
# Emails relating to user accounts. e.g. Confirming a new account
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class UserMailer < ApplicationMailer
  def confirm_login(user, reasons, url)
    @reasons, @name, @url = reasons, user.name, url
    headers('Return-Path' => blackhole_email, 'Reply-To' => contact_from_name_and_email) # we don't care about bounces when people are fiddling with their account

    mail(:from => contact_from_name_and_email,
         :to => user.name_and_email,
         :subject => reasons[:email_subject])
  end

  def already_registered(user, reasons, url)
    @reasons, @name, @url = reasons, user.name, url
    headers('Return-Path' => blackhole_email, 'Reply-To' => contact_from_name_and_email) # we don't care about bounces when people are fiddling with their account

    mail(:from => contact_from_name_and_email,
         :to => user.name_and_email,
         :subject => reasons[:email_subject])
  end

  def changeemail_confirm(user, new_email, url)
    @name, @url, @old_email, @new_email = user.name, url, user.email, new_email
    headers('Return-Path' => blackhole_email, 'Reply-To' => contact_from_name_and_email) # we don't care about bounces when people are fiddling with their account

    mail(:from => contact_from_name_and_email,
         :to => new_email,
         :subject => _("Confirm your new email address on {{site_name}}", :site_name => site_name))
  end

  def changeemail_already_used(old_email, new_email)
    @old_email, @new_email = old_email, new_email
    headers('Return-Path' => blackhole_email, 'Reply-To' => contact_from_name_and_email) # we don't care about bounces when people are fiddling with their account

    mail(:from => contact_from_name_and_email,
         :to => new_email,
         :subject => _("Unable to change email address on {{site_name}}", :site_name=>site_name))
  end
end
