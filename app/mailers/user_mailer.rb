# -*- encoding : utf-8 -*-
# models/user_mailer.rb:
# Emails relating to user accounts. e.g. Confirming a new account
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class UserMailer < ApplicationMailer
  def confirm_login(user, reasons, url)
    @reasons = reasons
    @name = user.name
    @url = url

    set_reply_to_headers(user)
    mail_user(user, reasons[:email_subject])
  end

  def already_registered(user, reasons, url)
    @reasons = reasons
    @name = user.name
    @url = url

    set_reply_to_headers(user)
    mail_user(user, reasons[:email_subject])
  end

  def changeemail_confirm(user, new_email, url)
    @name = user.name
    @url = url
    @old_email = user.email
    @new_email = new_email

    set_reply_to_headers(user)
    mail(from: contact_for_user(user),
         to: new_email,
         subject: _("Confirm your new email address on {{site_name}}", site_name: site_name))
  end

  def changeemail_already_used(old_email, new_email)
    @old_email = old_email
    @new_email = new_email
    user = User.find_by_email(@old_email)

    set_reply_to_headers(user)
    mail(from: contact_for_user(user),
         to: new_email,
         subject: _("Unable to change email address on {{site_name}}", site_name: site_name))
  end
end
