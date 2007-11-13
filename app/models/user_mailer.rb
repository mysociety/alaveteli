# models/user_mailer.rb:
# Emails relating to user accounts. e.g. Confirming a new account
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user_mailer.rb,v 1.2 2007-11-13 12:02:14 francis Exp $

class UserMailer < ActionMailer::Base

    def confirm_login(user, reasons, url)
        @from = MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost')
        @recipients = user.email
        @subject    = reasons[:email_subject]
        @body[:reasons] = reasons
        @body[:name] = user.name
        @body[:url] = url
    end

end

#'reason_web' => _("To view your pledges, we need to check your email address."),
#'reason_email' => _("Then you will be able to view your pledges."),
#'reason_email_subject' => _('View your pledges at PledgeBank.com')


