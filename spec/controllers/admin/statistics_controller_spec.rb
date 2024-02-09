require 'spec_helper'

RSpec.describe Admin::StatisticsController do
  describe 'GET #stats' do
    it 'assigns the number of public bodies to the view' do
      get :index
      expect(assigns[:public_body_count]).to eq PublicBody.count
    end

    it 'assigns the number of requests to the view' do
      get :index
      expect(assigns[:info_request_count]).to eq InfoRequest.count
    end

    it 'assigns the number of users to the view' do
      get :index
      expect(assigns[:user_count]).to eq User.count
    end

    it 'assigns the number of tracks to the view' do
      get :index
      expect(assigns[:track_thing_count]).to eq TrackThing.count
    end

    it 'assigns the number of comments to the view' do
      get :index
      expect(assigns[:comment_count]).to eq Comment.count
    end

    it 'assigns a Hash with grouped counts of requests by state to the view' do
      InfoRequest.destroy_all

      8.times { FactoryBot.create(:successful_request) }
      2.times { FactoryBot.create(:info_request) }
      FactoryBot.create(:attention_requested_request)

      get :index
      expect(assigns[:request_by_state]).
        to eq({ 'successful' => 8,
                'waiting_response' => 2,
                'attention_requested' => 1 })
    end

    it 'assigns a Hash with grouped counts of tracks by type to the view' do
      TrackThing.destroy_all

      FactoryBot.create(:search_track)
      2.times { FactoryBot.create(:public_body_track) }
      4.times { FactoryBot.create(:request_update_track) }
      6.times { FactoryBot.create(:successful_request_track) }
      7.times { FactoryBot.create(:new_request_track) }

      get :index
      expect(assigns[:tracks_by_type]).
        to eq({
          "search_query" => 1,
          "public_body_updates" => 2,
          "request_updates" => 4,
          "all_successful_requests" => 6,
          "all_new_requests" => 7 })
    end
  end
end
