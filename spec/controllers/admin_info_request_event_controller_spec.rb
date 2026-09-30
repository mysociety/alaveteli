require 'spec_helper'

RSpec.describe AdminInfoRequestEventController do
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

  describe 'GET #index' do
    before { sign_in(admin_user) }

    let(:info_request) { FactoryBot.create(:info_request) }
    let(:event) { info_request.info_request_events.first }

    it 'is successful' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns all info request events to the view' do
      get :index
      expect(assigns[:info_request_events]).to match_array(InfoRequestEvent.all)
    end

    it 'finds info request events matching a query' do
      event.update!(params: { email: 'foi@example.com' })
      get :index, params: { query: 'foi@example.com' }
      expect(assigns[:info_request_events]).to match_array([event])
    end

    context 'when a request is embargoed' do
      before { info_request.create_embargo }

      it 'does not include events if the current user is not a pro admin user' do
        get :index
        expect(assigns[:info_request_events]).not_to include(event)
      end

      it 'includes messages if the current user is a pro admin user' do
        sign_in pro_admin_user
        get :index
        expect(assigns[:info_request_events]).to include(event)
      end
    end
  end

  describe 'PUT update to mark event as clarification request' do
    let(:info_request_event) do
      info_request_event = FactoryBot.create(:response_event)
    end

    describe 'when handling valid data' do
      it 'gets the info request event' do
        put :update, params: {
          id: info_request_event,
          commit: 'Was clarification request'
        }
        expect(assigns[:info_request_event]).to eq(info_request_event)
      end

      it 'sets the described and calculated states on the event' do
        put :update, params: {
          id: info_request_event,
          commit: 'Was clarification request'
        }
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
            OutgoingMessage.new(status: 'ready',
                                message_type: 'followup',
                                what_doing: 'normal_sort',
                                info_request_id: info_request.id,
                                body: "Here's the clarification.")
          outgoing_message.record_email_delivery(
            'foi@example.com',
            'example.id'
          )
          outgoing_message.save!
          put :update, params: {
            id: info_request_event,
            commit: 'Was clarification request'
          }
          expect(info_request.reload.date_initial_request_last_sent_at).
            to eq(Time.zone.now.to_date)
        end
      end

      it 'shows a success notice' do
        put :update, params: {
          id: info_request_event,
          commit: 'Was clarification request'
        }
        expect(flash[:notice]).
          to eq(
            'Old response marked as having been a request for clarification'
          )
      end

      it 'redirects to the request admin page' do
        put :update, params: {
          id: info_request_event,
          commit: 'Was clarification request'
        }
        expect(response).
          to redirect_to(admin_request_url(info_request_event.info_request))
      end
    end

    it 'raises an exception if the event is not a response' do
      put :update, params: {
        id: info_request_event,
        commit: 'Was clarification request'
      }
      info_request_event = FactoryBot.create(:sent_event)
      expect {
        put :update, params: {
          id: info_request_event,
          commit: 'Was clarification request'
        }
      }.to raise_error(RuntimeError,
                       "can only mark responses as requires clarification")
    end
  end

  describe 'update InfoRequestEvent to remove PII' do
    let(:info_request_event) do
      info_request_event = FactoryBot.create(:edit_event)
    end

    it 'redirects to the info request list page' do
      put :update, params: {
        id: info_request_event,
        commit: 'Update event',
        info_request_event: {
          params_to_show: '{"key": "value"}'
        }
      }
      expect(response).
        to redirect_to(admin_info_request_events_url)
    end

    it 'shows an error message if invalid JSON is submitted' do
      put :update, params: {
        id: info_request_event,
        commit: 'Update event',
        info_request_event: {
          params_to_show: '{"key": broken}'
        }
      }
      expect(flash[:error]).
        to match(/^Invalid JSON conten/)
    end
  end
end
