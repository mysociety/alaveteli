# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminInfoRequestEventController do

  describe :update do

    describe 'when handling valid data' do

      before do
        @info_request_event = FactoryGirl.create(:info_request_event)
        put :update, :id => @info_request_event
      end

      it 'gets the info request event' do
        assigns[:info_request_event].should == @info_request_event
      end

      it 'sets the described and calculated states on the event' do
        event = InfoRequestEvent.find(@info_request_event.id)
        event.described_state.should == 'waiting_clarification'
        event.calculated_state.should == 'waiting_clarification'
      end

      it 'shows a success notice' do
        flash[:notice].should == 'Old response marked as having been a clarification'
      end

      it 'redirects to the request admin page' do
        response.should redirect_to(admin_request_url(@info_request_event.info_request))
      end
    end

    it 'raises an exception if the event is not a response' do
      @info_request_event = FactoryGirl.create(:sent_event)
      lambda{ put :update, :id => @info_request_event }.should raise_error
    end

  end

end
