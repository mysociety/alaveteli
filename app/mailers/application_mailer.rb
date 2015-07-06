# -*- encoding : utf-8 -*-
# models/application_mailer.rb:
# Shared code between different mailers.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'action_mailer/version'
class ApplicationMailer < ActionMailer::Base
    # Include all the functions views get, as emails call similar things.
    helper :application
    include MailerHelper

    # This really should be the default - otherwise you lose any information
    # about the errors, and have to do error checking on return codes.
    self.raise_delivery_errors = true

    def blackhole_email
        AlaveteliConfiguration::blackhole_prefix+"@"+AlaveteliConfiguration::incoming_email_domain
    end

    # URL generating functions are needed by all controllers (for redirects),
    # views (for links) and mailers (for use in emails), so include them into
    # all of all.
    include LinkToHelper

    # Site-wide access to configuration settings
    include ConfigHelper

end

