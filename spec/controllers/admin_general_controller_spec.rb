# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminGeneralController do

  describe "GET #index" do
    let(:admin_user){ FactoryGirl.create(:admin_user) }
    let(:pro_admin_user){ FactoryGirl.create(:pro_admin_user) }

    before do
      InfoRequest.destroy_all
    end

    it "should render the front page" do
      get :index, {}, { :user_id => admin_user.id }
      expect(response).to render_template('index')
    end

    it 'assigns old unclassified requests' do
      @old_request = FactoryGirl.create(:old_unclassified_request)
      get :index, {}, { :user_id => admin_user.id }
      expect(assigns[:old_unclassified]).to eq([@old_request])
    end

    it 'assigns requests that require admin to the view' do
      requires_admin_request = FactoryGirl.create(:requires_admin_request)
      get :index, {}, { :user_id => admin_user.id }
      expect(assigns[:requires_admin_requests]).to eq([requires_admin_request])
    end

    it 'assigns requests that have error messages to the view' do
      error_message_request = FactoryGirl.create(:error_message_request)
      get :index, {}, { :user_id => admin_user.id }
      expect(assigns[:error_message_requests]).to eq([error_message_request])
    end

    it 'assigns requests flagged for admin attention to the view' do
      attention_requested_request = FactoryGirl.create(:attention_requested_request)
      get :index, {}, { :user_id => admin_user.id }
      expect(assigns[:attention_requests]).to eq([attention_requested_request])
    end

    it 'assigns messages sent to the holding pen to the view' do
      undeliverable = FactoryGirl.
                        create(:incoming_message,
                               :info_request => InfoRequest.holding_pen_request)
      get :index, {}, { :user_id => admin_user.id }
      expect(assigns[:holding_pen_messages]).to eq([undeliverable])
    end

    context 'when the user is not a pro admin' do

      context 'when pro is enabled' do

        it 'does not assign embargoed requests that require admin to the view' do
          with_feature_enabled(:alaveteli_pro) do
            requires_admin_request = FactoryGirl.create(:requires_admin_request)
            requires_admin_request.create_embargo
            get :index, {}, { :user_id => admin_user.id }
            expect(assigns[:requires_admin_requests]).to eq([])
          end
        end

        it 'does not assign embargoed requests that have error messages to the view' do
          with_feature_enabled(:alaveteli_pro) do
            error_message_request = FactoryGirl.create(:error_message_request)
            error_message_request.create_embargo
            get :index, {}, { :user_id => admin_user.id }
            expect(assigns[:error_message_requests]).to eq([])
          end
        end

        it 'does not assign embargoed requests flagged for admin attention to the view' do
          with_feature_enabled(:alaveteli_pro) do
            attention_requested_request = FactoryGirl.create(:attention_requested_request)
            attention_requested_request.create_embargo
            get :index, {}, { :user_id => admin_user.id }
            expect(assigns[:attention_requests]).to eq([])
          end
        end

      end

      it 'does not assign embargoed requests that require admin to the view' do
        requires_admin_request = FactoryGirl.create(:requires_admin_request)
        requires_admin_request.create_embargo
        get :index, {}, { :user_id => admin_user.id }
        expect(assigns[:requires_admin_requests]).to eq([])
      end

      it 'does not assign embargoed requests that have error messages to the view' do
        error_message_request = FactoryGirl.create(:error_message_request)
        error_message_request.create_embargo
        get :index, {}, { :user_id => admin_user.id }
        expect(assigns[:error_message_requests]).to eq([])
      end

      it 'does not assign embargoed requests flagged for admin attention to the view' do
        attention_requested_request = FactoryGirl.create(:attention_requested_request)
        attention_requested_request.create_embargo
        get :index, {}, { :user_id => admin_user.id }
        expect(assigns[:attention_requests]).to eq([])
      end

    end

    context 'when the user is a pro admin and pro is enabled' do

      it 'assigns embargoed requests that require admin to the view' do
        with_feature_enabled(:alaveteli_pro) do
          requires_admin_request = FactoryGirl.create(:requires_admin_request)
          requires_admin_request.create_embargo
          get :index, {}, { :user_id => pro_admin_user.id }
          expect(assigns[:requires_admin_requests]).to eq([requires_admin_request])
        end
      end

      it 'assigns embargoed requests that have error messages to the view' do
        with_feature_enabled(:alaveteli_pro) do
          error_message_request = FactoryGirl.create(:error_message_request)
          error_message_request.create_embargo
          get :index, {}, { :user_id => pro_admin_user.id }
          expect(assigns[:error_message_requests]).to eq([error_message_request])
        end
      end

      it 'assigns embargoed requests flagged for admin attention to the view' do
        with_feature_enabled(:alaveteli_pro) do
          attention_requested_request = FactoryGirl.create(:attention_requested_request)
          attention_requested_request.create_embargo
          get :index, {}, { :user_id => pro_admin_user.id }
          expect(assigns[:attention_requests]).to eq([attention_requested_request])
        end
      end
    end

  end

  describe 'GET #timeline' do

    it 'should assign an array of events in order of descending date to the view' do

      info_request = FactoryGirl.create(:info_request)
      public_body = FactoryGirl.create(:public_body)

      first_event = info_request.log_event('edit', {})
      public_body.name = 'Changed name'
      public_body.save!
      public_body_version = public_body.versions.latest
      second_event = info_request.log_event('edit', {})

      get :timeline, :all => 1

      expect(assigns[:events].first.first).to  eq(second_event)
      expect(assigns[:events].second.first).to eq(public_body_version)
      expect(assigns[:events].third.first).to eq(first_event)

    end

  end

  describe 'GET #stats' do

    it 'assigns the number of public bodies to the view' do
      get :stats
      expect(assigns[:public_body_count]).to eq PublicBody.count
    end

    it 'assigns the number of requests to the view' do
      get :stats
      expect(assigns[:info_request_count]).to eq InfoRequest.count
    end

    it 'assigns the number of users to the view' do
      get :stats
      expect(assigns[:user_count]).to eq User.count
    end

    it 'assigns the number of tracks to the view' do
      get :stats
      expect(assigns[:track_thing_count]).to eq TrackThing.count
    end

    it 'assigns the number of comments to the view' do
      get :stats
      expect(assigns[:comment_count]).to eq Comment.count
    end

    it 'assigns a Hash with grouped counts of requests by state to the view' do
      InfoRequest.destroy_all

      8.times { FactoryGirl.create(:successful_request) }
      2.times { FactoryGirl.create(:info_request) }
      FactoryGirl.create(:attention_requested_request)

      get :stats
      expect(assigns[:request_by_state]).
        to eq({ 'successful' => 8,
                'waiting_response' => 2,
                'attention_requested' => 1 })
    end

    it 'assigns a Hash with grouped counts of tracks by type to the view' do
      TrackThing.destroy_all

      FactoryGirl.create(:search_track)
      2.times { FactoryGirl.create(:public_body_track) }
      4.times { FactoryGirl.create(:request_update_track) }
      6.times { FactoryGirl.create(:successful_request_track) }
      7.times { FactoryGirl.create(:new_request_track) }

      get :stats
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
