require 'spec_helper'

describe AdminInfoRequestEventController do

  describe 'PUT update' do
    let(:info_request_event) do
      info_request_event = FactoryBot.create(:response_event)
    end

    describe 'when handling valid data' do

      it 'gets the info request event' do
        put :update, params: { :id => info_request_event }
        expect(assigns[:info_request_event]).to eq(info_request_event)
      end

      it 'sets the described and calculated states on the event' do
        put :update, params: { :id => info_request_event }
        event = InfoRequestEvent.find(info_request_event.id)
        expect(event.described_state).to eq('waiting_clarification')
        expect(event.calculated_state).to eq('waiting_clarification')
      end

      it 'resets the last_sent_event on the info request if there is a
          subsequent follow up' do
        # create a follow up
        info_request = info_request_event.info_request
        travel_to(info_request.date_response_required_by) do
          outgoing_message =
            OutgoingMessage.new(:status => 'ready',
                                :message_type => 'followup',
                                :what_doing => 'normal_sort',
                                :info_request_id => info_request.id,
                                :body => "Here's the clarification.")
          outgoing_message.record_email_delivery(
            'foi@example.com',
            'example.id'
          )
          outgoing_message.save!
          put :update, params: { :id => info_request_event }
          expect(info_request.reload.date_initial_request_last_sent_at).
            to eq(Time.zone.now.to_date)
        end
      end

      it 'shows a success notice' do
        put :update, params: { :id => info_request_event }
        expect(flash[:notice]).
          to eq('Old response marked as having been a request for clarification')
      end

      it 'redirects to the request admin page' do
        put :update, params: { :id => info_request_event }
        expect(response).
          to redirect_to(admin_request_url(info_request_event.info_request))
      end
    end

    it 'raises an exception if the event is not a response' do
      put :update, params: { :id => info_request_event }
      info_request_event = FactoryBot.create(:sent_event)
      expect {
        put :update, params: { :id => info_request_event }
      }.to raise_error(RuntimeError,
                       "can only mark responses as requires clarification")
    end

  end

end
