# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TrackController, "when making a new track on a request" do
    before(:each) do
        @ir = mock_model(InfoRequest, :url_title => 'myrequest',
                                      :title => 'My request')
        @track_thing = mock_model(TrackThing, :save! => true,
                                              :params => {},
                                              :track_medium= => nil,
                                              :tracking_user_id= => nil)
        TrackThing.stub!(:create_track_for_request).and_return(@track_thing)
        TrackThing.stub!(:create_track_for_search_query).and_return(@track_thing)
        TrackThing.stub!(:find_existing).and_return(nil)
        InfoRequest.stub!(:find_by_url_title!) do |url_title|
          if url_title == "myrequest"
            @ir
          else
            raise ActiveRecord::RecordNotFound.new("Not found")
          end
        end

        @user = mock_model(User)
        User.stub!(:find).and_return(@user)
        @user.stub!(:locale).and_return("en")
        @user.stub!(:receive_email_alerts).and_return(true)
        @user.stub!(:url_name).and_return("bob")
    end

    it "should require login when making new track" do
        get :track_request, :url_title => @ir.url_title, :feed => 'track'
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
    end

    it "should save a request track and redirect if you are logged in" do
        session[:user_id] = @user.id
        @track_thing.should_receive(:save!)
        get :track_request, :url_title => @ir.url_title, :feed => 'track'
        response.should redirect_to(:controller => 'request', :action => 'show', :url_title => @ir.url_title)
    end

    it "should 404 for non-existent requests" do
      session[:user_id] = @user.id
      lambda {
        get :track_request, :url_title => "hjksfdhjk_louytu_qqxxx", :feed => 'track'
      }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should save a search track and redirect to the right place" do
        session[:user_id] = @user.id
        @track_thing.should_receive(:save!)
        get :track_search_query, :query_array => "bob variety:sent", :feed => 'track'
        response.should redirect_to(:controller => 'general', :action => 'search', :combined => ["bob", "requests"])
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
        TrackThing.find(:first, :conditions => ['id = ? ', @track_thing.id]).should == nil
    end

    it 'should redirect to a URL on the site' do
        get :update, {:track_id => @track_thing.id,
                      :track_medium => 'delete',
                      :r => '/'},
                     {:user_id => @track_thing.tracking_user.id}
        response.should redirect_to('/')
    end

    it 'should not redirect to a url on another site' do
        track_thing = FactoryGirl.create(:search_track)
        get :update, {:track_id => @track_thing.id,
                      :track_medium => 'delete',
                      :r => 'http://example.com/'},
                     {:user_id => @track_thing.tracking_user.id}
        response.should redirect_to('/')
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
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.body.should =~ /Alter your subscription/
        mail.to_addrs.first.to_s.should include(users(:silly_name_user).email)
        mail.body.to_s =~ /(http:\/\/.*\/c\/(.*))/
        mail_url = $1
        mail_token = $2

        mail.body.should_not =~ /&amp;/

        mail.body.should_not include('sent a request') # request not included
        mail.body.should_not include('sent a response') # response not included
        mail.body.should include('added an annotation') # comment included

        mail.body.should =~ /This a the daftest comment the world has ever seen/ # comment text included
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
        post_redirect.uri.should == expected_url

        # Check nothing more is delivered if we try again
        deliveries.clear
        TrackMailer.alert_tracks
        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 0
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
        mail.body.should include('el equipo de ')
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
        response.should render_template('track/atom_feed')
        response.content_type.should == 'application/atom+xml'
        # TODO: should check it is an atom.builder type being rendered, not sure how to

        assigns[:xapian_object].matches_estimated.should == 3
        assigns[:xapian_object].results.size.should == 3
        assigns[:xapian_object].results[0][:model].should == info_request_events(:silly_comment_event) # created_at 2008-08-12 23:05:12.500942
        assigns[:xapian_object].results[1][:model].should == info_request_events(:useless_incoming_message_event) # created_at 2007-11-13 18:09:20.042061
        assigns[:xapian_object].results[2][:model].should == info_request_events(:useless_outgoing_message_event) # created_at 2007-10-14 10:41:12.686264
    end

    it "should return NotFound for a non-existent user" do
        lambda {
            get :track_user, :feed => 'feed', :url_name => "there_is_no_such_user"
        }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should return atom/xml for a feed url without format specified, even if the
        requester prefers json' do

        request.env['HTTP_ACCEPT'] = 'application/json,text/xml'
        track_thing = track_things(:track_fancy_dog_request)

        get :track_request, :feed => 'feed', :url_title => track_thing.info_request.url_title
        response.should render_template('track/atom_feed')
        response.content_type.should == 'application/atom+xml'
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
        a.class.to_s.should == 'Array'
        a.size.should == 3

        a[0]['id'].should == info_request_events(:silly_comment_event).id
        a[1]['id'].should == info_request_events(:useless_incoming_message_event).id
        a[2]['id'].should == info_request_events(:useless_outgoing_message_event).id

        a[0]['info_request']['url_title'].should == 'why_do_you_have_such_a_fancy_dog'
        a[1]['info_request']['url_title'].should == 'why_do_you_have_such_a_fancy_dog'
        a[2]['info_request']['url_title'].should == 'why_do_you_have_such_a_fancy_dog'

        a[0]['public_body']['url_name'].should == 'tgq'
        a[1]['public_body']['url_name'].should == 'tgq'
        a[2]['public_body']['url_name'].should == 'tgq'

        a[0]['user']['url_name'].should == 'bob_smith'
        a[1]['user']['url_name'].should == 'bob_smith'
        a[2]['user']['url_name'].should == 'bob_smith'

        a[0]['event_type'].should == 'comment'
        a[1]['event_type'].should == 'response'
        a[2]['event_type'].should == 'sent'

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
        response.should be_success
        response.should render_template('track/atom_feed')
        tt = assigns[:track_thing]
        tt.public_body.should == geraldine
        tt.track_type.should == 'public_body_updates'
        tt.track_query.should == "requested_from:" + geraldine.url_name
    end

    it "should filter by event type" do
        geraldine = public_bodies(:geraldine_public_body)
        get :track_public_body, :feed => 'feed', :url_name => geraldine.url_name, :event_type => 'sent'
        response.should be_success
        response.should render_template('track/atom_feed')
        tt = assigns[:track_thing]
        tt.public_body.should == geraldine
        tt.track_type.should == 'public_body_updates'
        tt.track_query.should == "requested_from:" + geraldine.url_name + " variety:sent"
    end

end
