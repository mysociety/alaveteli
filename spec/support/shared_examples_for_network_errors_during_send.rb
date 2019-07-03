# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'NetworkSendErrors' do

  describe 'handles a network error during message sending' do

    before do
      allow_any_instance_of(ActionMailer::MessageDelivery).
        to receive(:deliver_now).
          and_raise(Errno::ETIMEDOUT)

      send_request
    end

    it 'does not send the email' do
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
    end

    it 'sets the described_state of the request to "error_message"' do
      expect(request.reload.described_state).to eq('error_message')
    end

    it 'logs a "send_error" event' do
      event = request.reload.info_request_events.last
      expect(event.event_type).to eq 'send_error'
    end

    it 'stores the reason for the failure' do
      event = request.reload.info_request_events.last
      expect(event.params[:reason]).to eq 'Connection timed out'
    end

    it 'ensures that the outgoing message is persisted' do
      expect(outgoing_message).to be_persisted
    end

    it 'ensures that the outgoing message status is set to "failed"' do
      expect(outgoing_message.status).to eq 'failed'
    end

  end

end
