class RequestMailbox < ApplicationMailbox
  def process
    mail = inbound_email.mail

    # Only check mail that doesn't have spam in the header
    return if SpamAddress.spam?(MailHandler.get_all_addresses(mail))

    # Find exact matches for info requests
    exact_info_requests = requests_matching_email(mail)

    if exact_info_requests.count > 0
      # Go through each exact info request and deliver the email
      exact_info_requests.each do |info_request|
        info_request.receive(mail)
      end

      return
    end

    # If there are no exact matches, find any guessed requests
    guessed_info_requests = Guess.guessed_info_requests(mail)

    if guessed_info_requests.count == 1
      # If there one guess automatically redeliver the email to that and log it
      # as an event
      info_request = guessed_info_requests.first
      info_request.log_event(
        'redeliver_incoming',
        editor: 'automatic',
        destination_request: info_request
      )
      info_request.receive(mail)

    else
      # Otherwise we send the mail to the holding pen
      send_to_holding_pen(mail)
    end
  end

  private

  # Find which info requests the email is for
  def requests_matching_email(mail)
    addresses = MailHandler.get_all_addresses(mail)
    InfoRequest.matching_incoming_email(addresses)
  end

  def send_to_holding_pen(mail)
    reason = _("Could not identify the request from the email address")
    InfoRequest.holding_pen_request.receive(mail, rejected_reason: reason)
  end
end
