# -*- encoding : utf-8 -*-
# models/notification_mailer.rb:
# Emails relating to notifications from the site
#
# Copyright (c) 2017 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class NotificationMailer < ApplicationMailer
  def response_notification(notification)
    @info_request = notification.info_request_event.info_request
    @incoming_message = notification.info_request_event.incoming_message

    set_reply_to_headers(@info_request.user)
    set_auto_generated_headers

    mail(
      :from => contact_for_user(@info_request.user),
      :to => @info_request.user.name_and_email,
      :subject => _("New response to your FOI request - {{request_title}}",
                    :request_title => @info_request.title.html_safe),
      :charset => "UTF-8",
      :template_name => 'new_response'
    )
  end
end
