# -*- encoding : utf-8 -*-
# models/info_request_batch_mailer.rb:
# Emails relating to user accounts. e.g. Confirming a new account
#
# Copyright (c) 2013 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class InfoRequestBatchMailer < ApplicationMailer

  def batch_sent(info_request_batch, unrequestable, user)
    @info_request_batch, @unrequestable = info_request_batch, unrequestable
    headers('Return-Path' => blackhole_email, 'Reply-To' => contact_from_name_and_email)

    # Make a link going to the info request batch page, which logs the user in.
    post_redirect = PostRedirect.new(
      :uri => info_request_batch_url(@info_request_batch),
    :user_id => info_request_batch.user_id)
    post_redirect.save!
    @url = confirm_url(:email_token => post_redirect.email_token)

    mail(:from => contact_from_name_and_email,
         :to => user.name_and_email,
         :subject => _("Your batch request \"{{title}}\" has been sent",
                       :title => info_request_batch.title))
  end
end
