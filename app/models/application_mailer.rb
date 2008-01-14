# models/application_mailer.rb:
# Shared code between different mailers.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: application_mailer.rb,v 1.1 2008-01-14 12:23:28 francis Exp $

class ApplicationMailer < ActionMailer::Base
    helper :application

    def contact_from_name_and_email
        "GovernmentSpy <"+MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost')+">"
    end
end

