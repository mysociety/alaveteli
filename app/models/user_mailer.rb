# models/user_mailer.rb:
# Emails relating to user accounts. e.g. Confirming a new account
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user_mailer.rb,v 1.8 2009-02-09 10:37:12 francis Exp $

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

end

