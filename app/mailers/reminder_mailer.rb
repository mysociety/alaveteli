# -*- encoding : utf-8 -*-

class ReminderMailer < ApplicationMailer
  # Send reminder message to administrator
  def public_holidays(name, email, subject)
    # Return path is an address we control so that SPF checks are done on it.
    headers(
      'Return-Path' => blackhole_email,
      'Reply-To' => MailHandler.address_from_name_and_email(name, email)
    )

    mail(:from => MailHandler.address_from_name_and_email(name, email),
         :to => MailHandler.address_from_name_and_email(name, email),
         :subject => subject)
  end
end
