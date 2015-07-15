# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WidgetsController do

  include LinkToHelper

  describe 'GET show' do

    before do
      @info_request = FactoryGirl.create(:info_request)
      AlaveteliConfiguration.stub!(:enable_widgets).and_return(true)
    end

    it 'should render the widget template' do
      get :show, :request_id => @info_request.id
      expect(response).to render_template('show')
    end

    it 'should find the info request' do
      get :show, :request_id => @info_request.id
      assigns[:info_request].should == @info_request
    end

    it 'should create a track thing for the request' do
      get :show, :request_id => @info_request.id
      assigns[:track_thing].info_request.should == @info_request
    end

    it 'should assign the request status' do
      get :show, :request_id => @info_request.id
      assigns[:status].should == @info_request.calculate_status
    end

    it 'assigns the count of follows the request has' do
      TrackThing.delete_all
      WidgetVote.delete_all

      track = TrackThing.create_track_for_request(@info_request)
      track.track_medium = 'email_daily'
      track.tracking_user = FactoryGirl.create(:user)
      track.save!

      3.times do
        @info_request.widget_votes.create(:cookie => SecureRandom.hex(10))
      end

      get :show, :request_id => @info_request.id

      # Count should be 5
      # 1 for the request's owning user
      # 1 track thing
      # 3 widget votes
      expect(assigns[:count]).to eq(5)
    end

    it 'sets user_owns_request to true if the user owns the request' do
      session[:user_id] = @info_request.user.id
      get :show, :request_id => @info_request.id
      expect(assigns[:user_owns_request]).to be_true
    end

    it 'sets user_owns_request to false if the user does not own the request' do
      session[:user_id] = FactoryGirl.create(:user).id
      get :show, :request_id => @info_request.id
      expect(assigns[:user_owns_request]).to be_false
    end

    it 'should not send an x-frame-options header' do
      get :show, :request_id => @info_request.id
      response.headers["X-Frame-Options"].should be_nil
    end

    context 'for a non-logged-in user with a tracking cookie' do

      it 'will not find existing tracks' do
        request.cookies['widget_vote'] = mock_cookie
        get :show, :request_id => @info_request.id
        expect(assigns[:existing_track]).to be_nil
      end

      it 'finds existing votes' do
        vote = FactoryGirl.create(:widget_vote,
                                  :info_request => @info_request,
                                  :cookie => mock_cookie)
        request.cookies['widget_vote'] = vote.cookie
        get :show, :request_id => @info_request.id
        expect(assigns[:existing_vote]).to be_true
      end

      it 'will not find any existing votes if none exist' do
        WidgetVote.delete_all
        request.cookies['widget_vote'] = mock_cookie
        get :show, :request_id => @info_request.id
        expect(assigns[:existing_vote]).to be_false
      end

    end

    context 'for a non-logged-in user without a tracking cookie' do

      it 'will not find existing tracks' do
        request.cookies['widget_vote'] = nil
        get :show, :request_id => @info_request.id
        expect(assigns[:existing_track]).to be_nil
      end

      it 'will not find any existing votes' do
        request.cookies['widget_vote'] = nil
        get :show, :request_id => @info_request.id
        expect(assigns[:existing_vote]).to be_false
      end

    end

    context 'for a logged in user with tracks' do

      it 'finds the existing track thing' do
        user = FactoryGirl.create(:user)
        track = TrackThing.create_track_for_request(@info_request)
        track.track_medium = 'email_daily'
        track.tracking_user = user
        track.save!
        session[:user_id] = user.id

        get :show, :request_id => @info_request.id

        expect(assigns[:existing_track]).to eq(track)
      end

    end

    context 'for a logged in user without tracks' do

      it 'does not find existing track things' do
        TrackThing.delete_all
        user = FactoryGirl.create(:user)
        session[:user_id] = user.id

        get :show, :request_id => @info_request.id

        expect(assigns[:existing_track]).to be_nil
      end

      it 'looks for an existing vote' do
        TrackThing.delete_all
        vote = FactoryGirl.create(:widget_vote,
                                  :info_request => @info_request,
                                  :cookie => mock_cookie)
        session[:user_id] = @info_request.user.id
        request.cookies['widget_vote'] = mock_cookie

        get :show, :request_id => @info_request.id

        expect(assigns[:existing_vote]).to be_true
      end

      it 'will not find any existing votes if none exist' do
        TrackThing.delete_all
        WidgetVote.delete_all
        session[:user_id] = @info_request.user.id
        request.cookies['widget_vote'] = mock_cookie

        get :show, :request_id => @info_request.id

        expect(assigns[:existing_vote]).to be_false
      end

    end

    context 'when widgets are not enabled' do

      it 'raises ActiveRecord::RecordNotFound' do
        AlaveteliConfiguration.stub!(:enable_widgets).and_return(false)
        lambda{ get :show, :request_id => @info_request.id }.should
        raise_error(ActiveRecord::RecordNotFound)
      end

    end

    context "when the request's prominence is not 'normal'" do

      it 'should return a 403' do
        @info_request.prominence = 'hidden'
        @info_request.save!
        get :show, :request_id => @info_request.id
        response.code.should == "403"
      end

      it 'does not look for an existing vote' do
        vote = FactoryGirl.create(:widget_vote,
                                  :info_request => @info_request,
                                  :cookie => mock_cookie)
        session[:user_id] = @info_request.user.id

        get :show, :request_id => @info_request.id

        expect(assigns[:existing_vote]).to be_false
      end

    end

  end

  describe 'GET new' do

    before do
      @info_request = FactoryGirl.create(:info_request)
      AlaveteliConfiguration.stub!(:enable_widgets).and_return(true)
    end

    it 'should render the create widget template' do
      get :new, :request_id => @info_request.id
      expect(response).to render_template('new')
    end

    it 'should find the info request' do
      get :new, :request_id => @info_request.id
      assigns[:info_request].should == @info_request
    end

    context 'when widgets are not enabled' do

      it 'raises ActiveRecord::RecordNotFound' do
        AlaveteliConfiguration.stub!(:enable_widgets).and_return(false)
        lambda{ get :new, :request_id => @info_request.id }.should
        raise_error(ActiveRecord::RecordNotFound)
      end

    end

    context "when the request's prominence is not 'normal'" do

      it 'should return a 403' do
        @info_request.prominence = 'hidden'
        @info_request.save!
        get :show, :request_id => @info_request.id
        response.code.should == "403"
      end

    end

  end

end

def mock_cookie
  '0300fd3e1177127cebff'
end
