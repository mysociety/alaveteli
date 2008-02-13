# models/application_mailer.rb:
# Shared code between different mailers.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: application_mailer.rb,v 1.3 2008-02-13 08:12:10 francis Exp $

class ApplicationMailer < ActionMailer::Base
    # Include all the functions views get, as emails call similar things.
    helper :application

    self.raise_delivery_errors = true

    def contact_from_name_and_email
        "GovernmentSpy <"+MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost')+">"
    end
end

