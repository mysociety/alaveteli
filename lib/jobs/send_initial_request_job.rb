class SendInitialRequestJob

    attr_reader :outgoing_message, :info_request, :mail_message

    def initialize(outgoing_message, opts = {})
        @outgoing_message = outgoing_message
        @info_request = opts.fetch(:info_request) { outgoing_message.info_request }
        @mail_message = opts.fetch(:mail_message) { create_default_mail_message }
    end

    def before
        outgoing_message.send_message
    end

    def perform
        mail_message.deliver
    end

    def after
        info_request.log_event(log_event_type, log_event_params)
        info_request.set_described_state('waiting_response')
    end

    private

    def log_event_type
        'sent'
    end

    def log_event_params
        { :email               => mail_message.to_addrs.join(', '),
          :outgoing_message_id => outgoing_message.id,
          :smtp_message_id     => mail_message.message_id }
    end

    def create_default_mail_message
        OutgoingMailer.initial_request(info_request, outgoing_message)
    end

end
