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

    subject = reasons[:email_subject] || _(
      'Confirm your account on {{site_name}}', site_name: site_name
    )
    mail_user(user, subject: -> { subject })
  end

  def already_registered(user, reasons, url)
    @reasons = reasons
    @name = user.name
    @url = url

    subject = reasons[:email_subject] || _(
      'Your account on {{site_name}}', site_name: site_name
    )
    mail_user(user, subject: -> { subject })
  end

  def changeemail_confirm(user, new_email, url)
    @name = user.name
    @url = url
    @old_email = user.email
    @new_email = new_email

    # Cannot send the user to mail_user - that would send to old_email.
    # No problem if the current locale is the user's.
    subject = _(
      "Confirm your new email address on {{site_name}}",
      site_name: site_name
    )
    mail_user(user, subject: -> { subject })
  end

  def changeemail_already_used(old_email, new_email)
    @old_email = old_email
    @new_email = new_email
    user = User.find_by_email(@old_email)

    # Cannot send the user to mail_user - that would send to old_email.
    # No problem if the current locale is the user's.
    subject = _(
      "Unable to change email address on {{site_name}}",
      site_name: site_name
    )
    mail_user(new_email, subject: -> { subject })
  end
end
