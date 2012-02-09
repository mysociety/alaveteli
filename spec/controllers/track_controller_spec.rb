require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'json'

describe TrackController, "when making a new track on a request" do
    before do
        @ir = mock_model(InfoRequest, :url_title => 'myrequest',
                                      :title => 'My request')
        @track_thing = mock_model(TrackThing, :save! => true,
                                              :params => {:list_description => 'list description'},
                                              :track_medium= => nil,
                                              :tracking_user_id= => nil)
        TrackThing.stub!(:create_track_for_request).and_return(@track_thing)
        TrackThing.stub!(:find_by_existing_track).and_return(nil)
        InfoRequest.stub!(:find_by_url_title).and_return(@ir)

        @user = mock_model(User)
        User.stub!(:find).and_return(@user)
        @user.stub!(:locale).and_return("en")
    end

    it "should require login when making new track" do
        get :track_request, :url_title => @ir.url_title, :feed => 'track'
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
    end

    it "should save the track and redirect if you are logged in" do
        session[:user_id] = @user.id
        @track_thing.should_receive(:save!)
        get :track_request, :url_title => @ir.url_title, :feed => 'track'
        response.should redirect_to(:controller => 'request', :action => 'show', :url_title => @ir.url_title)
    end

end

describe TrackController, "when sending alerts for a track" do
    integrate_views
    include LinkToHelper # for main_url

    before(:each) do
        load_raw_emails_data
        rebuild_xapian_index
    end
    
    it "should send alerts" do
        # Don't do clever locale-insertion-unto-URL stuff
        old_filters = ActionController::Routing::Routes.filters
        ActionController::Routing::Routes.filters = RoutingFilter::Chain.new

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
        mail.body =~ /(http:\/\/.*\/c\/(.*))/
        mail_url = $1
        mail_token = $2

        mail.body.should_not =~ /&amp;/

        mail.body.should_not include('sent a request') # request not included
        mail.body.should_not include('sent a response') # response not included
        mail.body.should include('added an annotation') # comment included

        mail.body.should =~ /This a the daftest comment the world has ever seen/ # comment text included
        # Check subscription managing link
# XXX We can't do this, as it is redirecting to another controller. I'm
# apparently meant to be writing controller unit tests here, not functional
# tests.  Bah, I so don't care, bit of an obsessive constraint.
#        session[:user_id].should be_nil
#        controller.test_code_redirect_by_email_token(mail_token, self) # XXX hack to avoid having to call User controller for email link
#        session[:user_id].should == users(:silly_name_user).id
#
#        response.should render_template('users/show')
#        assigns[:display_user].should == users(:silly_name_user)

        # Given we can't click the link, check the token is right instead
        post_redirect = PostRedirect.find_by_email_token(mail_token)
        expected_url = main_url("/user/" + users(:silly_name_user).url_name + "#email_subscriptions") # XXX can't call URL making functions here, what is correct way to do this?
        post_redirect.uri.should == expected_url

        # Check nothing more is delivered if we try again
        deliveries.clear
        TrackMailer.alert_tracks
        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 0

        # Restore the routing filters
        ActionController::Routing::Routes.filters = old_filters
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
    integrate_views

    before(:each) do
        load_raw_emails_data
        rebuild_xapian_index
    end

    it "should get the RSS feed" do
        track_thing = track_things(:track_fancy_dog_request)

        get :track_request, :feed => 'feed', :url_title => track_thing.info_request.url_title
        response.should render_template('track/atom_feed')
        # XXX should check it is an atom.builder type being rendered, not sure how to

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
end

describe TrackController, "when viewing JSON version of a track feed" do

    integrate_views

    before(:each) do
        load_raw_emails_data
        rebuild_xapian_index
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




