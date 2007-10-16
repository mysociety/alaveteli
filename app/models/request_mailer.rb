# models/request_mailer.rb:
# Emails which go to public bodies on behalf of users.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_mailer.rb,v 1.1 2007-10-16 08:57:32 francis Exp $

class RequestMailer < ActionMailer::Base

  def initial_request(info_request, outgoing_message)
    @from = 'francis@flourish.org' # XXX
    @recipients = 'frabcus@fastmail.fm'
    # XXX check with staging site
    #@recipients = info_request.public_body.request_email
    @subject    = 'Freedom of Information Request - ' + info_request.title
    @body       = {:info_request => info_request, :outgoing_message => outgoing_message}
  end

end
