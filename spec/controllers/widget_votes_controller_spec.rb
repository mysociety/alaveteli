# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WidgetVotesController do

  include LinkToHelper

  describe 'POST create' do

    before do
      @info_request = FactoryGirl.create(:info_request)
      allow(AlaveteliConfiguration).to receive(:enable_widgets).and_return(true)
    end

    it 'should find the info request' do
      post :create, :request_id => @info_request.id
      expect(assigns[:info_request]).to eq(@info_request)
    end

    it 'should redirect to the track path for the info request' do
      post :create, :request_id => @info_request.id
      track_thing = TrackThing.create_track_for_request(@info_request)
      expect(response).to redirect_to(do_track_path(track_thing))
    end

    context 'for a non-logged-in user without a tracking cookie' do

      it 'sets a tracking cookie' do
        allow(SecureRandom).to receive(:hex).and_return(mock_cookie)
        post :create, :request_id => @info_request.id
        expect(cookies[:widget_vote]).to eq(mock_cookie)
      end

      it 'creates a widget vote' do
        allow(SecureRandom).to receive(:hex).and_return(mock_cookie)
        votes = @info_request.
          widget_votes.
          where(:cookie => mock_cookie)

        post :create, :request_id => @info_request.id

        expect(votes.size).to eq(1)
      end

    end

    context 'for a non-logged-in user with a tracking cookie' do

      it 'retains the existing tracking cookie' do
        request.cookies['widget_vote'] = mock_cookie
        post :create, :request_id => @info_request.id
        expect(cookies[:widget_vote]).to eq(mock_cookie)
      end

      it 'creates a widget vote' do
        request.cookies['widget_vote'] = mock_cookie
        votes = @info_request.
          widget_votes.
          where(:cookie => mock_cookie)

        post :create, :request_id => @info_request.id

        expect(votes.size).to eq(1)
      end

    end

    context 'when widgets are not enabled' do

      it 'raises ActiveRecord::RecordNotFound' do
        allow(AlaveteliConfiguration).to receive(:enable_widgets).and_return(false)
        expect{ post :create, :request_id => @info_request.id }.
          to raise_error(ActiveRecord::RecordNotFound)
      end

    end

    context "when the request's prominence is not 'normal'" do

      it 'should return a 403' do
        @info_request.prominence = 'hidden'
        @info_request.save!
        post :create, :request_id => @info_request.id
        expect(response.code).to eq("403")
      end

    end

  end

end

def mock_cookie
  '0300fd3e1177127cebff'
end
