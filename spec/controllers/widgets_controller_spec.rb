require 'spec_helper'

RSpec.describe WidgetsController do
  include LinkToHelper

  describe 'GET show' do
    before do
      @info_request = FactoryBot.create(:info_request)
      allow(AlaveteliConfiguration).to receive(:enable_widgets).and_return(true)
    end

    it 'should render the widget template' do
      get :show, params: { request_url_title: @info_request.url_title }
      expect(response).to render_template('show')
    end

    it 'should find the info request' do
      get :show, params: { request_url_title: @info_request.url_title }
      expect(assigns[:info_request]).to eq(@info_request)
    end

    it 'should create a track thing for the request' do
      get :show, params: { request_url_title: @info_request.url_title }
      expect(assigns[:track_thing].info_request).to eq(@info_request)
    end

    it 'should assign the request status' do
      get :show, params: { request_url_title: @info_request.url_title }
      expect(assigns[:status]).to eq(@info_request.calculate_status)
    end

    it 'assigns the count of follows the request has' do
      TrackThing.delete_all
      WidgetVote.delete_all

      track = TrackThing.create_track_for_request(@info_request)
      track.track_medium = 'email_daily'
      track.tracking_user = FactoryBot.create(:user)
      track.save!

      3.times do
        @info_request.widget_votes.create(cookie: SecureRandom.hex(10))
      end

      get :show, params: { request_url_title: @info_request.url_title }

      # Count should be 5
      # 1 for the request's owning user
      # 1 track thing
      # 3 widget votes
      expect(assigns[:count]).to eq(5)
    end

    it 'sets user_owns_request to true if the user owns the request' do
      sign_in @info_request.user
      get :show, params: { request_url_title: @info_request.url_title }
      expect(assigns[:user_owns_request]).to be true
    end

    it 'sets user_owns_request to false if the user does not own the request' do
      sign_in FactoryBot.create(:user)
      get :show, params: { request_url_title: @info_request.url_title }
      expect(assigns[:user_owns_request]).to be false
    end

    it 'should not send an x-frame-options header' do
      get :show, params: { request_url_title: @info_request.url_title }
      expect(response.headers["X-Frame-Options"]).to be_nil
    end

    context 'for a non-logged-in user with a tracking cookie' do
      it 'will not find existing tracks' do
        request.cookies['widget_vote'] = mock_cookie
        get :show, params: { request_url_title: @info_request.url_title }
        expect(assigns[:existing_track]).to be_nil
      end

      it 'finds existing votes' do
        vote = FactoryBot.create(:widget_vote,
                                 info_request: @info_request,
                                 cookie: mock_cookie)
        request.cookies['widget_vote'] = vote.cookie
        get :show, params: { request_url_title: @info_request.url_title }
        expect(assigns[:existing_vote]).to be true
      end

      it 'will not find any existing votes if none exist' do
        WidgetVote.delete_all
        request.cookies['widget_vote'] = mock_cookie
        get :show, params: { request_url_title: @info_request.url_title }
        expect(assigns[:existing_vote]).to be false
      end
    end

    context 'for a non-logged-in user without a tracking cookie' do
      it 'will not find existing tracks' do
        request.cookies['widget_vote'] = nil
        get :show, params: { request_url_title: @info_request.url_title }
        expect(assigns[:existing_track]).to be_nil
      end

      it 'will not find any existing votes' do
        request.cookies['widget_vote'] = nil
        get :show, params: { request_url_title: @info_request.url_title }
        expect(assigns[:existing_vote]).to be false
      end
    end

    context 'for a logged in user with tracks' do
      it 'finds the existing track thing' do
        user = FactoryBot.create(:user)
        track = TrackThing.create_track_for_request(@info_request)
        track.track_medium = 'email_daily'
        track.tracking_user = user
        track.save!
        sign_in user

        get :show, params: { request_url_title: @info_request.url_title }

        expect(assigns[:existing_track]).to eq(track)
      end
    end

    context 'for a logged in user without tracks' do
      it 'does not find existing track things' do
        TrackThing.delete_all
        user = FactoryBot.create(:user)
        sign_in user

        get :show, params: { request_url_title: @info_request.url_title }

        expect(assigns[:existing_track]).to be_nil
      end

      it 'looks for an existing vote' do
        TrackThing.delete_all
        vote = FactoryBot.create(:widget_vote,
                                 info_request: @info_request,
                                 cookie: mock_cookie)
        sign_in @info_request.user
        request.cookies['widget_vote'] = mock_cookie

        get :show, params: { request_url_title: @info_request.url_title }

        expect(assigns[:existing_vote]).to be true
      end

      it 'will not find any existing votes if none exist' do
        TrackThing.delete_all
        WidgetVote.delete_all
        sign_in @info_request.user
        request.cookies['widget_vote'] = mock_cookie

        get :show, params: { request_url_title: @info_request.url_title }

        expect(assigns[:existing_vote]).to be false
      end
    end

    context 'when widgets are not enabled' do
      it 'raises ActiveRecord::RecordNotFound' do
        allow(AlaveteliConfiguration).
          to receive(:enable_widgets).
          and_return(false)
        expect {
          get :show, params: { request_url_title: @info_request.url_title }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the request's prominence is not 'normal'" do
      it 'should return a 403' do
        @info_request.prominence = 'hidden'
        @info_request.save!
        get :show, params: { request_url_title: @info_request.url_title }
        expect(response.code).to eq("403")
      end

      it 'does not look for an existing vote' do
        vote = FactoryBot.create(:widget_vote,
                                 info_request: @info_request,
                                 cookie: mock_cookie)
        sign_in @info_request.user

        get :show, params: { request_url_title: @info_request.url_title }

        expect(assigns[:existing_vote]).to be false
      end
    end
  end

  describe 'GET new' do
    before do
      @info_request = FactoryBot.create(:info_request)
      allow(AlaveteliConfiguration).
        to receive(:enable_widgets).
        and_return(true)
    end

    it 'should render the create widget template' do
      get :new, params: { request_url_title: @info_request.url_title }
      expect(response).to render_template('new')
    end

    it 'should find the info request' do
      get :new, params: { request_url_title: @info_request.url_title }
      expect(assigns[:info_request]).to eq(@info_request)
    end

    context 'when widgets are not enabled' do
      it 'raises ActiveRecord::RecordNotFound' do
        allow(AlaveteliConfiguration).
          to receive(:enable_widgets).
          and_return(false)
        expect {
          get :new, params: { request_url_title: @info_request.url_title }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the request's prominence is not 'normal'" do
      it 'should return a 403' do
        @info_request.prominence = 'hidden'
        @info_request.save!
        get :show, params: { request_url_title: @info_request.url_title }
        expect(response.code).to eq("403")
      end
    end
  end
end

def mock_cookie
  '0300fd3e1177127cebff'
end
