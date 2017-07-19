# -*- encoding : utf-8 -*-
# app/controllers/admin_raw_email_controller.rb:
# Controller for managing raw emails from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminRawEmailController < AdminController

  before_filter :set_raw_email, :only => [:show]

  def show
    respond_to do |format|
      format.html do
        # For the holding pen, try to guess where it should be ...
        @holding_pen = false
        if (@raw_email.incoming_message.info_request == InfoRequest.holding_pen_request && !@raw_email.incoming_message.empty_from_field?)
          @holding_pen = true

          # 1. Use domain of email to try and guess which public body it
          # is associated with, so we can display that.
          email = @raw_email.incoming_message.from_email
          domain = PublicBody.extract_domain_from_email(email)
          @public_bodies = if domain.nil?
            []
          else
            PublicBody.
              with_translations(I18n.locale).
                where("lower(public_body_translations.request_email) " \
                      "like lower('%'||?||'%')", domain).
                  order('public_body_translations.name')
          end

          # 2. Match the email address in the message without matching the hash
          @info_requests =  InfoRequest.guess_by_incoming_email(@raw_email.incoming_message)

          # 3. Give a reason why it's in the holding pen
          last_event = InfoRequestEvent.find_by_incoming_message_id(@raw_email.incoming_message.id)
          @rejected_reason = last_event.params[:rejected_reason] || "unknown reason"
        end
      end
      format.text do
        render :body => @raw_email.data, :content_type => 'message/rfc822'
      end
    end
  end

  private

  def set_raw_email
    @raw_email = RawEmail.find(params[:id])
  end

end
