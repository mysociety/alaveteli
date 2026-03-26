class RequestMailbox < ApplicationMailbox
  def process
    return if spam?

    if exact_info_requests.count > 0
      # Go through each exact info request and deliver the email
      exact_info_requests.each do |info_request|
        info_request.receive(mail, **args)
      end

    elsif guessed_info_requests.count == 1
      # If there one guess automatically redeliver the email to that and log it
      # as an event
      info_request = guessed_info_requests.first
      info_request.log_event(
        'redeliver_incoming',
        editor: 'automatic',
        destination_request: info_request
      )
      info_request.receive(mail, **args)

    else
      # Otherwise we send the mail to the holding pen
      send_to_holding_pen
    end
  end

  private

  def addresses
    @addresses ||= MailHandler.get_all_addresses(mail)
  end

  def spam?
    SpamAddress.spam?(addresses)
  end

  def exact_info_requests
    @exact_info_requests ||= InfoRequest.matching_incoming_email(addresses)
  end

  def guessed_info_requests
    @guessed_info_requests ||= Guess.guessed_info_requests(addresses)
  end

  def send_to_holding_pen
    reason = _("Could not identify the request from the email address")
    InfoRequest.holding_pen_request.receive(
      mail, **args(rejected_reason: reason)
    )
  end

  def args(**extra_args)
    extra_args.merge(
      message_id: inbound_email.message_id,
      message_checksum: inbound_email.message_checksum
    )
  end
end
