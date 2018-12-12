# -*- encoding : utf-8 -*-
# Emails about PublicBodyChangeRequests.
class PublicBodyChangeRequestMailer < ApplicationMailer
  # Send a request to the administrator to add an authority
  def change_request_message(change_request, use_new_body_template)
    @change_request = change_request
    template =
      if use_new_body_template
        'add_public_body'
      else
        'update_public_body_email'
      end

    # From is an address we control so that strict DMARC senders don't get refused
    from_address = MailHandler.address_from_name_and_email(
      @change_request.get_user_name,
      blackhole_email)

    reply_to_address = MailHandler.address_from_name_and_email(
      @change_request.get_user_name,
      @change_request.get_user_email)

    set_reply_to_headers(nil, 'Reply-To' => reply_to_address)

    mail(:from => from_address,
         :to => contact_from_name_and_email,
         :subject => @change_request.request_subject,
         :template_name => template)
  end
end
