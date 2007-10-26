# models/request_mailer.rb:
# Emails which go to public bodies on behalf of users.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_mailer.rb,v 1.3 2007-10-26 18:00:26 francis Exp $

class RequestMailer < ActionMailer::Base

  def initial_request(info_request, outgoing_message)
    @from = info_request.incoming_email
    if MySociety::Config.getbool("STAGING_SITE", 1)
        @recipients = @from
    else
        @recipients = info_request.public_body.request_email
    end
    @subject    = 'Freedom of Information Request - ' + info_request.title
    @body       = {:info_request => info_request, :outgoing_message => outgoing_message}
  end

  def receive(email)
    # Find which info requests the email is for
    info_requests = []
    for address in (email.to || []) + (email.cc || [])
        info_request = InfoRequest.find_by_incoming_email(address)
        info_requests.push(info_request) if info_request
    end

    # Deal with each on
    for info_request in info_requests
        info_request.receive(email)
    end

    #    email.cc
#     page = Page.find_by_address(email.to.first)
#      page.emails.create(
#        :subject => email.subject, :body => email.body
#      )
#
#      if email.has_attachments?
#        for attachment in email.attachments
#          page.attachments.create({
#            :file => attachment, :description => email.subject
#          })
#        end
#      end
  end

end
