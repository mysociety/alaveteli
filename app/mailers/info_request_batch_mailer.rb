# models/info_request_batch_mailer.rb:
# Emails relating to user accounts. e.g. Confirming a new account
#
# Copyright (c) 2013 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class InfoRequestBatchMailer < ApplicationMailer
  def batch_sent(info_request_batch, unrequestable, user)
    @info_request_batch = info_request_batch
    @unrequestable = unrequestable
    @url = info_request_batch_url(@info_request_batch)

    mail_user(
      user,
      subject: -> { _(
        "Your batch request \"{{title}}\" has been sent",
        title: info_request_batch.title.html_safe
      ) }
    )
  end
end
