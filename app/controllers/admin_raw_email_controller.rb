# app/controllers/admin_raw_email_controller.rb:
# Controller for managing raw emails from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminRawEmailController < AdminController
  before_action :set_raw_email, only: [:show]

  def show
    respond_to do |format|
      format.html do
        @holding_pen = in_holding_pen?(@raw_email) ? true : false

        # For the holding pen, try to guess where it should be…
        if @holding_pen
          # 1. Use domain of email to try and guess which public body it
          # is associated with, so we can display that.
          @public_bodies = PublicBody.with_domain(@raw_email.from_email_domain)

          # 2. Match the email address in the message without matching the hash
          guess_addresses = @raw_email.addresses(include_invalid: true)
          @guessed_info_requests =
            InfoRequest.guess_by_incoming_email(guess_addresses)

          # 3. Match the email subject in the message
          guess_by_subject =
            InfoRequest.guess_by_incoming_subject(@raw_email.subject)
          @guessed_info_requests =
            (@guessed_info_requests + guess_by_subject).
              select(&:info_request).uniq(&:info_request)

          # 4. Give a reason why it's in the holding pen
          @rejected_reason = rejected_reason(@raw_email) || 'unknown reason'
        end
      end

      format.eml do
        render body: @raw_email.data, content_type: 'message/rfc822'
      end
    end
  end

  private

  def set_raw_email
    @raw_email = RawEmail.find(params[:id])
  end

  def in_holding_pen?(raw_email)
    raw_email.incoming_message.info_request.holding_pen_request? &&
      !raw_email.empty_from_field?
  end

  def rejected_reason(raw_email)
    last_event =
      InfoRequestEvent.
        find_by_incoming_message_id(raw_email.incoming_message.id)

    last_event.params[:rejected_reason]
  end
end
