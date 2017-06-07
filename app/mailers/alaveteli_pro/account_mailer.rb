# -*- encoding : utf-8 -*-
# Account requests
#
# Copyright (c) 2017 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/
module AlaveteliPro
  class AccountMailer < ApplicationMailer

    def account_request(account_request)
      @account_request = account_request
      set_reply_to_headers(nil, 'Reply-To' => @account_request.email)

      # From is an address we control so that strict DMARC senders don't get refused
      mail(:from => blackhole_email,
           :to => pro_contact_from_name_and_email,
           :subject => _("{{pro_site_name}} account request",
                         pro_site_name: AlaveteliConfiguration.pro_site_name)
          )
    end
  end
end
