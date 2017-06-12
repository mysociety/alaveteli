# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminInfoRequestEventController do

  describe 'PUT update' do
    let(:info_request_event) do
      info_request_event = FactoryGirl.create(:response_event)
    end

    describe 'when handling valid data' do

      it 'gets the info request event' do
        put :update, :id => info_request_event
        expect(assigns[:info_request_event]).to eq(info_request_event)
      end

      it 'sets the described and calculated states on the event' do
        put :update, :id => info_request_event
        event = InfoRequestEvent.find(info_request_event.id)
        expect(event.described_state).to eq('waiting_clarification')
        expect(event.calculated_state).to eq('waiting_clarification')
      end

      it 'shows a success notice' do
        put :update, :id => info_request_event
        expect(flash[:notice]).
          to eq('Old response marked as having been a clarification')
      end

      it 'redirects to the request admin page' do
        put :update, :id => info_request_event
        expect(response).
          to redirect_to(admin_request_url(info_request_event.info_request))
      end
    end

    it 'raises an exception if the event is not a response' do
      put :update, :id => info_request_event
      info_request_event = FactoryGirl.create(:sent_event)
      expect{ put :update, :id => info_request_event }.
        to raise_error(RuntimeError,
          "can only mark responses as requires clarification")
    end

  end

end
