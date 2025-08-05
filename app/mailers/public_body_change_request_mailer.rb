# -*- encoding : utf-8 -*-
# Emails about PublicBodyChangeRequests.
class PublicBodyChangeRequestMailer < ApplicationMailer
  # Send a request to the administrator to add a new PublicBody.
  def add_public_body(change_request)
    change_request_message(change_request, 'add_public_body')
  end

  # Send a request to the administrator to update the email of an existing
  # PublicBody.
  def update_public_body(change_request)
    change_request_message(change_request, 'update_public_body')
  end

  private

  def change_request_message(change_request, template)
    @change_request = change_request

    # From is an address we control so that strict DMARC senders don't get
    # refused
    from_address = MailHandler.address_from_name_and_email(
      @change_request.get_user_name,
      blackhole_email)

    reply_to_address = MailHandler.address_from_name_and_email(
      @change_request.get_user_name,
      @change_request.get_user_email)

    set_reply_to_headers(nil, 'Reply-To' => reply_to_address)

    mail(from: from_address,
         to: contact_from_name_and_email,
         subject: @change_request.request_subject,
         template_name: template)
  end
end
