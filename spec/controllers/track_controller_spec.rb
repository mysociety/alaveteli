# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TrackController do

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

end

describe TrackController, "when making a new track on a request" do
  before(:each) do
    @ir = mock_model(InfoRequest, :url_title => 'myrequest',
                     :title => 'My request')
    @track_thing = mock_model(TrackThing, :save! => true,
                              :params => {},
                              :track_medium= => nil,
                              :tracking_user_id= => nil)
    allow(TrackThing).to receive(:create_track_for_request).and_return(@track_thing)
    allow(TrackThing).to receive(:create_track_for_search_query).and_return(@track_thing)
    allow(TrackThing).to receive(:find_existing).and_return(nil)
    allow(InfoRequest).to receive(:find_by_url_title!) do |url_title|
      if url_title == "myrequest"
        @ir
      else
        raise ActiveRecord::RecordNotFound.new("Not found")
      end
    end

    @user = mock_model(User)
    allow(User).to receive(:find).and_return(@user)
    allow(@user).to receive(:locale).and_return("en")
    allow(@user).to receive(:receive_email_alerts).and_return(true)
    allow(@user).to receive(:url_name).and_return("bob")
  end

  it "should require login when making new track" do
    get :track_request, :url_title => @ir.url_title, :feed => 'track'
    expect(response).to redirect_to(:controller => 'user',
                                    :action => 'signin',
                                    :token => get_last_post_redirect.token)
  end

  it "should save a request track and redirect if you are logged in" do
    session[:user_id] = @user.id
    expect(@track_thing).to receive(:save!)
    get :track_request, :url_title => @ir.url_title, :feed => 'track'
    expect(response).to redirect_to(:controller => 'request', :action => 'show', :url_title => @ir.url_title)
  end

  it "should 404 for non-existent requests" do
    session[:user_id] = @user.id
    expect {
      get :track_request, :url_title => "hjksfdhjk_louytu_qqxxx", :feed => 'track'
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "should save a search track and redirect to the right place" do
    session[:user_id] = @user.id
    expect(@track_thing).to receive(:save!)
    get :track_search_query, :query_array => "bob variety:sent", :feed => 'track'
    expect(response).to redirect_to(:controller => 'general', :action => 'search', :combined => ["bob", "requests"])
  end

end

describe TrackController, "when unsubscribing from a track" do

  before do
    @track_thing = FactoryGirl.create(:search_track)
  end

  it 'should destroy the track thing' do
    get :update, {:track_id => @track_thing.id,
                  :track_medium => 'delete',
    :r => 'http://example.com'},
      {:user_id => @track_thing.tracking_user.id}
    expect(TrackThing.find(:first, :conditions => ['id = ? ', @track_thing.id])).to eq(nil)
  end

  it 'should redirect to a URL on the site' do
    get :update, {:track_id => @track_thing.id,
                  :track_medium => 'delete',
    :r => '/'},
      {:user_id => @track_thing.tracking_user.id}
    expect(response).to redirect_to('/')
  end

  it 'should not redirect to a url on another site' do
    track_thing = FactoryGirl.create(:search_track)
    get :update, {:track_id => @track_thing.id,
                  :track_medium => 'delete',
    :r => 'http://example.com/'},
      {:user_id => @track_thing.tracking_user.id}
    expect(response).to redirect_to('/')
  end

end

describe TrackController, "when sending alerts for a track" do
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
    expected_url = show_user_url(:url_name => users(:silly_name_user).url_name, :anchor => "email_subscriptions")
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

describe TrackController, "when viewing RSS feed for a track" do
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
    expect {
      get :track_user, :feed => 'feed', :url_name => "there_is_no_such_user"
    }.to raise_error(ActiveRecord::RecordNotFound)
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

describe TrackController, "when viewing JSON version of a track feed" do

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

describe TrackController, "when tracking a public body" do

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
    get :track_public_body, :feed => 'feed', :url_name => geraldine.url_name, :event_type => 'sent'
    expect(response).to be_success
    expect(response).to render_template('track/atom_feed')
    tt = assigns[:track_thing]
    expect(tt.public_body).to eq(geraldine)
    expect(tt.track_type).to eq('public_body_updates')
    expect(tt.track_query).to eq("requested_from:" + geraldine.url_name + " variety:sent")
  end

end

def mock_cookie
  '0300fd3e1177127cebff'
end
