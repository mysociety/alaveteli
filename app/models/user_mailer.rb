# models/user_mailer.rb:
# Emails relating to user accounts. e.g. Confirming a new account
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/

class UserMailer < ApplicationMailer
    def confirm_login(user, reasons, url)
        @from = contact_from_name_and_email
        headers 'Return-Path' => blackhole_email, 'Reply-To' => @from # we don't care about bounces when people are fiddling with their account
        @recipients = user.name_and_email
        @subject    = reasons[:email_subject]
        @body[:reasons] = reasons
        @body[:name] = user.name
        @body[:url] = url
    end

    def already_registered(user, reasons, url)
        @from = contact_from_name_and_email
        headers 'Return-Path' => blackhole_email, 'Reply-To' => @from # we don't care about bounces when people are fiddling with their account
        @recipients = user.name_and_email
        @subject    = reasons[:email_subject]
        @body[:reasons] = reasons
        @body[:name] = user.name
        @body[:url] = url
    end

    def changeemail_confirm(user, new_email, url)
        @from = contact_from_name_and_email
        headers 'Return-Path' => blackhole_email, 'Reply-To' => @from # we don't care about bounces when people are fiddling with their account
        @recipients = new_email
        @subject    = _("Confirm your new email address on {{site_name}}", :site_name=>site_name)
        @body[:name] = user.name
        @body[:url] = url
        @body[:old_email] = user.email
        @body[:new_email] = new_email
    end

    def changeemail_already_used(old_email, new_email)
        @from = contact_from_name_and_email
        headers 'Return-Path' => blackhole_email, 'Reply-To' => @from # we don't care about bounces when people are fiddling with their account
        @recipients = new_email
        @subject    = _("Unable to change email address on {{site_name}}", :site_name=>site_name)
        @body[:old_email] = old_email
        @body[:new_email] = new_email
    end
end

