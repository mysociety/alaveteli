# models/request_mailer.rb:
# Emails which go to public bodies on behalf of users.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_mailer.rb,v 1.2 2007-10-24 11:39:37 francis Exp $

class RequestMailer < ActionMailer::Base

  def initial_request(info_request, outgoing_message)
    @from = info_request.user.email
    if MySociety::Config.getbool("STAGING_SITE", 1)
        @recipients = @from
    else
        @recipients = info_request.public_body.request_email
    end
    @subject    = 'Freedom of Information Request - ' + info_request.title
    @body       = {:info_request => info_request, :outgoing_message => outgoing_message}
  end

end
