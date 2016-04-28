# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TrackController do
  let(:mock_cookie) { '0300fd3e1177127cebff' }

  describe 'GET track_request' do
    it 'clears widget votes for the request' do
      allow(AlaveteliConfiguration).to receive(:enable_widgets).and_return(true)
      @info_request = FactoryGirl.create(:info_request)
      @info_request.widget_votes.create(:cookie => mock_cookie)

      session[:user_id] = FactoryGirl.create(:user).id
      request.cookies['widget_vote'] = mock_cookie

      get :track_request, :url_title => @info_request.url_title, :feed => 'track'
      expect(@info_request.reload.widget_votes).to be_empty
    end
  end

  describe "when making a new track on a request" do
    let(:ir) do
      FactoryGirl.create(:info_request,
                          :title => 'My request',
                          :url_title => 'myrequest')
    end

    let(:track_thing) do
      FactoryGirl.create(:request_update_track,
                         :info_request => ir,
                         :track_medium => 'email_daily',
                         :track_query => 'example')
    end

    let(:user) { FactoryGirl.create(:user, :locale => 'en', :name => 'bob') }

    it "should require login when making new track" do
      get :track_request, :url_title => ir.url_title, :feed => 'track'
      expect(response).to redirect_to(:controller => 'user',
                                      :action => 'signin',
                                      :token => get_last_post_redirect.token)
    end

    it "should set no-cache headers on the login redirect" do
      get :track_request, :url_title => ir.url_title, :feed => 'track'
      expect(response.headers["Cache-Control"]).
        to eq('no-cache, no-store, max-age=0, must-revalidate')
      expect(response.headers['Pragma']).to eq('no-cache')
      expect(response.headers['Expires']).to eq('0')
    end

    it "should save a request track and redirect if you are logged in" do
      session[:user_id] = user.id
      allow(TrackThing).to receive(:create_track_for_request).and_return(track_thing)
      expect(track_thing).to receive(:save).and_call_original
      get :track_request, :url_title => ir.url_title, :feed => 'track'
      expect(response).to redirect_to(:controller => 'request',
                                      :action => 'show', :url_title => ir.url_title)
    end

    it "should 404 for non-existent requests" do
      session[:user_id] = user.id
      expect { get :track_request, :url_title => "hjksfdh_louytu_qqxxx", :feed => 'track' }.
        to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "when making a search track" do
    let(:track_thing) do
      FactoryGirl.create(:search_track,
                         :track_medium => 'email_daily',
                         :track_query => 'example')
    end

    let(:user) { FactoryGirl.create(:user, :locale => 'en', :name => 'bob') }

    it "should save a search track and redirect to the right place" do
      session[:user_id] = user.id
      allow(TrackThing).to receive(:create_track_for_search_query).and_return(track_thing)
      expect(track_thing).to receive(:save).and_call_original
      get :track_search_query, :query_array => "bob variety:sent", :feed => 'track'
      expect(response).to redirect_to(:controller => 'general', :action => 'search',
                                      :combined => ["bob", "requests"])
    end

    it "should redirect with an error message if the query is too long" do
      long_track = TrackThing.new(:track_type => 'search_query',
                                  :track_query => "lorem ipsum " * 42)
      session[:user_id] = user.id
      allow(TrackThing).to receive(:create_track_for_search_query).and_return(long_track)
      get :track_search_query, :query_array => "bob variety:sent", :feed => 'track'
      expect(flash[:error]).to match('too long')
      expect(response).to redirect_to(:controller => 'general', :action => 'search',
                                      :combined => ["bob", "requests"])
    end
  end

  describe "when making a new track on a public body" do
    let(:public_body) { FactoryGirl.create(:public_body) }
    let(:user) { FactoryGirl.create(:user, :locale => 'en', :name => 'bob') }

    it "should save a search track and redirect to the right place" do
      session[:user_id] = user.id
      track_thing = TrackThing.new(:track_type => 'public_body_updates',
                                   :public_body => public_body)
      allow(TrackThing).to receive(:create_track_for_public_body).and_return(track_thing)
      expect(track_thing).to receive(:save).and_call_original
      get :track_public_body, :url_name => public_body.url_name,
                              :feed => 'track', :event_type => 'sent'
      expect(response).to redirect_to("/body/#{public_body.url_name}")
    end

    it "should redirect with an error message if the query is too long" do
      session[:user_id] = user.id
      long_track = TrackThing.new(:track_type => 'public_body_updates',
                                  :public_body => public_body,
                                  :track_query => "lorem ipsum " * 42)
      allow(TrackThing).to receive(:create_track_for_public_body).and_return(long_track)
      get :track_public_body, :url_name => public_body.url_name,
                              :feed => 'track', :event_type => 'sent'
      expect(flash[:error]).to match('too long')
      expect(response).to redirect_to("/body/#{public_body.url_name}")
    end
  end

  describe "when making a new track on a user" do
    let(:target_user) { FactoryGirl.create(:user) }
    let(:user) { FactoryGirl.create(:user) }

    it "should save a user track and redirect to the right place" do
      session[:user_id] = user.id
      track_thing = TrackThing.new(:track_type => 'user_updates',
                                   :tracked_user => target_user,
                                   :track_query => "requested_by:#{target_user.url_name}")
      allow(TrackThing).to receive(:create_track_for_user).and_return(track_thing)
      expect(track_thing).to receive(:save).and_call_original
      get :track_user, :url_name => target_user.url_name, :feed => 'track'
      expect(response).to redirect_to("/user/#{target_user.url_name}")
    end

    it "should redirect with an error message if the query is too long" do
      session[:user_id] = user.id
      long_track = TrackThing.new(:track_type => 'user_updates',
                                  :tracked_user => target_user,
                                  :track_query => "lorem ipsum " * 42)
      allow(TrackThing).to receive(:create_track_for_user).and_return(long_track)
      get :track_user, :url_name => target_user.url_name, :feed => 'track'
      expect(flash[:error]).to match('too long')
      expect(response).to redirect_to("/user/#{target_user.url_name}")
    end
  end

  describe "when making a new track on a list" do
    let(:user) { FactoryGirl.create(:user) }

    it "should save a list track and redirect to the right place" do
      session[:user_id] = user.id
      track_thing = TrackThing.new(:track_type => 'all_new_requests',
                                   :track_query => "variety:sent")
      allow(TrackThing).to receive(:create_track_for_all_new_requests).
        and_return(track_thing)
      expect(track_thing).to receive(:save).and_call_original
      get :track_list, :view => 'recent', :feed => 'track'
      expect(response).to redirect_to("/list?view=recent")
    end

    it "should redirect with an error message if the query is too long" do
      session[:user_id] = user.id
      long_track = TrackThing.new(:track_type => 'all_new_requests',
                                  :track_query => "lorem ipsum " * 42)
      allow(TrackThing).to receive(:create_track_for_all_new_requests).
        and_return(long_track)
      get :track_list, :view => 'recent', :feed => 'track'
      expect(flash[:error]).to match('too long')
      expect(response).to redirect_to("/list?view=recent")
    end
  end

  describe "when unsubscribing from a track" do
    let(:track_thing) { FactoryGirl.create(:search_track) }

    it 'should destroy the track thing' do
      get :update, {:track_id => track_thing.id,
                    :track_medium => 'delete',
                    :r => 'http://example.com'},
                   {:user_id => track_thing.tracking_user.id}
      expect(TrackThing.find(:first, :conditions => ['id = ? ', track_thing.id])).to eq(nil)
    end

    it 'should redirect to a URL on the site' do
      get :update, {:track_id => track_thing.id,
                    :track_medium => 'delete',
                    :r => '/'},
                   {:user_id => track_thing.tracking_user.id}
      expect(response).to redirect_to('/')
    end

    it 'should not redirect to a url on another site' do
      track_thing = FactoryGirl.create(:search_track)
      get :update, {:track_id => track_thing.id,
                    :track_medium => 'delete',
                    :r => 'http://example.com/'},
                   {:user_id => track_thing.tracking_user.id}
      expect(response).to redirect_to('/')
    end
  end

  describe "when sending alerts for a track" do
    render_views

    before(:each) do
      load_raw_emails_data
      get_fixtures_xapian_index
    end

    it "should send alerts" do
      # set the time the comment event happened at to within the last week
      ire = info_request_events(:silly_comment_event)
      ire.created_at = Time.now - 3.days
      ire.save!

      TrackMailer.alert_tracks

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.body).to match(/Alter your subscription/)
      expect(mail.to_addrs.first.to_s).to include(users(:silly_name_user).email)
      mail.body.to_s =~ /(http:\/\/.*\/c\/(.*))/
      mail_url = $1
      mail_token = $2

      expect(mail.body).not_to match(/&amp;/)

      expect(mail.body).not_to include('sent a request') # request not included
      expect(mail.body).not_to include('sent a response') # response not included
      expect(mail.body).to include('added an annotation') # comment included

      expect(mail.body).to match(/This a the daftest comment the world has ever seen/) # comment text included
      # Check subscription managing link
      # TODO: We can't do this, as it is redirecting to another controller. I'm
      # apparently meant to be writing controller unit tests here, not functional
      # tests.  Bah, I so don't care, bit of an obsessive constraint.
      #        session[:user_id].should be_nil
      #        controller.test_code_redirect_by_email_token(mail_token, self) # TODO: hack to avoid having to call User controller for email link
      #        session[:user_id].should == users(:silly_name_user).id
      #
      #        response.should render_template('users/show')
      #        assigns[:display_user].should == users(:silly_name_user)

      # Given we can't click the link, check the token is right instead
      post_redirect = PostRedirect.find_by_email_token(mail_token)
      expected_url = show_user_url(:url_name => users(:silly_name_user).url_name,
                                   :anchor => "email_subscriptions")
      expect(post_redirect.uri).to eq(expected_url)

      # Check nothing more is delivered if we try again
      deliveries.clear
      TrackMailer.alert_tracks
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
    end

    it "should send localised alerts" do
      # set the time the comment event happened at to within the last week
      ire = info_request_events(:silly_comment_event)
      ire.created_at = Time.now - 3.days
      ire.save!
      user = users(:silly_name_user)
      user.locale = "es"
      user.save!
      TrackMailer.alert_tracks
      deliveries = ActionMailer::Base.deliveries
      mail = deliveries[0]
      expect(mail.body).to include('el equipo de ')
    end
  end

  describe "when viewing RSS feed for a track" do
    render_views

    before(:each) do
      load_raw_emails_data
      get_fixtures_xapian_index
    end

    it "should get the RSS feed" do
      track_thing = track_things(:track_fancy_dog_request)

      get :track_request, :feed => 'feed', :url_title => track_thing.info_request.url_title
      expect(response).to render_template('track/atom_feed')
      expect(response.content_type).to eq('application/atom+xml')
      # TODO: should check it is an atom.builder type being rendered, not sure how to

      expect(assigns[:xapian_object].matches_estimated).to eq(3)
      expect(assigns[:xapian_object].results.size).to eq(3)
      expect(assigns[:xapian_object].results[0][:model]).to eq(info_request_events(:silly_comment_event)) # created_at 2008-08-12 23:05:12.500942
      expect(assigns[:xapian_object].results[1][:model]).to eq(info_request_events(:useless_incoming_message_event)) # created_at 2007-11-13 18:09:20.042061
      expect(assigns[:xapian_object].results[2][:model]).to eq(info_request_events(:useless_outgoing_message_event)) # created_at 2007-10-14 10:41:12.686264
    end

    it "should return NotFound for a non-existent user" do
      expect { get :track_user, :feed => 'feed', :url_name => "there_is_no_such_user" }.
        to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should return atom/xml for a feed url without format specified, even if the
          requester prefers json' do

      request.env['HTTP_ACCEPT'] = 'application/json,text/xml'
      track_thing = track_things(:track_fancy_dog_request)

      get :track_request, :feed => 'feed', :url_title => track_thing.info_request.url_title
      expect(response).to render_template('track/atom_feed')
      expect(response.content_type).to eq('application/atom+xml')
    end
  end

  describe "when viewing JSON version of a track feed" do
    render_views

    before(:each) do
      load_raw_emails_data
      get_fixtures_xapian_index
    end

    it "should get the feed" do
      track_thing = track_things(:track_fancy_dog_request)

      get :track_request, :feed => 'feed', :url_title => track_thing.info_request.url_title, :format => "json"

      a = JSON.parse(response.body)
      expect(a.class.to_s).to eq('Array')
      expect(a.size).to eq(3)

      expect(a[0]['id']).to eq(info_request_events(:silly_comment_event).id)
      expect(a[1]['id']).to eq(info_request_events(:useless_incoming_message_event).id)
      expect(a[2]['id']).to eq(info_request_events(:useless_outgoing_message_event).id)

      expect(a[0]['info_request']['url_title']).to eq('why_do_you_have_such_a_fancy_dog')
      expect(a[1]['info_request']['url_title']).to eq('why_do_you_have_such_a_fancy_dog')
      expect(a[2]['info_request']['url_title']).to eq('why_do_you_have_such_a_fancy_dog')

      expect(a[0]['public_body']['url_name']).to eq('tgq')
      expect(a[1]['public_body']['url_name']).to eq('tgq')
      expect(a[2]['public_body']['url_name']).to eq('tgq')

      expect(a[0]['user']['url_name']).to eq('bob_smith')
      expect(a[1]['user']['url_name']).to eq('bob_smith')
      expect(a[2]['user']['url_name']).to eq('bob_smith')

      expect(a[0]['event_type']).to eq('comment')
      expect(a[1]['event_type']).to eq('response')
      expect(a[2]['event_type']).to eq('sent')
    end
  end

  describe "when tracking a public body" do
    render_views

    before(:each) do
      load_raw_emails_data
      get_fixtures_xapian_index
    end

    it "should work" do
      geraldine = public_bodies(:geraldine_public_body)
      get :track_public_body, :feed => 'feed', :url_name => geraldine.url_name
      expect(response).to be_success
      expect(response).to render_template('track/atom_feed')
      tt = assigns[:track_thing]
      expect(tt.public_body).to eq(geraldine)
      expect(tt.track_type).to eq('public_body_updates')
      expect(tt.track_query).to eq("requested_from:" + geraldine.url_name)
    end

    it "should filter by event type" do
      geraldine = public_bodies(:geraldine_public_body)
      get :track_public_body,
            :feed => 'feed', :url_name => geraldine.url_name, :event_type => 'sent'
      expect(response).to be_success
      expect(response).to render_template('track/atom_feed')
      tt = assigns[:track_thing]
      expect(tt.public_body).to eq(geraldine)
      expect(tt.track_type).to eq('public_body_updates')
      expect(tt.track_query).to eq("requested_from:" + geraldine.url_name + " variety:sent")
    end
  end

  describe 'POST delete_all_type' do

    let(:track_thing) { FactoryGirl.create(:search_track) }

    context 'when the user passed in the params is not logged in' do

      it 'redirects to the signin page' do
        post :delete_all_type, :user => track_thing.tracking_user.id,
                               :track_type => 'search_query'
        expect(response).to redirect_to(:controller => 'user',
                                        :action => 'signin',
                                        :token => get_last_post_redirect.token)
      end

    end

    context 'when the user passed in the params is logged in' do

      it 'deletes all tracks for the user of the type passed in the params' do
        post :delete_all_type, {:user => track_thing.tracking_user.id,
                                :track_type => 'search_query',
                                :r => '/'},
                               {:user_id => track_thing.tracking_user.id}
        expect(TrackThing.where(:id => track_thing.id)).to be_empty
      end

      it 'redirects to the redirect path in the param passed' do
        post :delete_all_type, {:user => track_thing.tracking_user.id,
                        :track_type => 'search_query',
                        :r => '/'},
                       {:user_id => track_thing.tracking_user.id}
        expect(response).to redirect_to('/')
      end

      it 'shows a message telling the user what has happened' do
        post :delete_all_type, {:user => track_thing.tracking_user.id,
                        :track_type => 'search_query',
                        :r => '/'},
                       {:user_id => track_thing.tracking_user.id}
        expect(flash[:notice]).to eq("You will no longer be emailed updates for those alerts")
      end

    end

  end
end
