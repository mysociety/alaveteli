# The special holding pen InfoRequest. IncomingMessages get delivered here if we
# can't route them to the correct request.
module InfoRequest::HoldingPen
  extend ActiveSupport::Concern

  class_methods do
    # The "holding pen" is a special request which stores incoming emails whose
    # destination request is unknown.
    def holding_pen_request
      ir = InfoRequest.find_by_url_title("holding_pen")

      if ir.nil?
        ir = InfoRequest.new(
          user: User.internal_admin_user,
          public_body: PublicBody.internal_admin_body,
          title: 'Holding pen',
          described_state: 'waiting_response',
          awaiting_description: false,
          prominence: 'hidden'
        )

        om = OutgoingMessage.new({
          status: 'ready',
          message_type: 'initial_request',
          body: 'This is the holding pen request. It shows responses that ' \
                'were sent to invalid addresses, and need moving to the ' \
                'correct request by an administrator.',
          last_sent_at: Time.zone.now,
          what_doing: 'normal_sort'

        })

        ir.outgoing_messages << om
        om.info_request = ir

        ir.save!

        ir.log_event(
          'sent',
          outgoing_message_id: om.id,
          email: ir.public_body.request_email
        )
      end
      ir
    end
  end

  def holding_pen_request?
    return true if url_title == 'holding_pen'

    self == self.class.holding_pen_request
  end
end
