# models/application_mailer.rb:
# Shared code between different mailers.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: application_mailer.rb,v 1.4 2008-02-19 12:13:07 francis Exp $

class ApplicationMailer < ActionMailer::Base
    # Include all the functions views get, as emails call similar things.
    helper :application

    self.raise_delivery_errors = true

    def contact_from_name_and_email
        "foi.mysociety.org <"+MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost')+">"
    end
end

