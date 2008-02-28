# models/application_mailer.rb:
# Shared code between different mailers.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: application_mailer.rb,v 1.6 2008-02-28 14:25:51 francis Exp $

class ApplicationMailer < ActionMailer::Base
    # Include all the functions views get, as emails call similar things.
    helper :application

    # This really should be the default - otherwise you lose any information
    # about the errors, and have to do error checking on return codes.
    self.raise_delivery_errors = true

    def contact_from_name_and_email
        "WhatDoTheyKnow <"+MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost')+">"
    end
end

