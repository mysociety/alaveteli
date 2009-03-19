require File.dirname(__FILE__) + '/../spec_helper'

describe TrackController, "when making a new track on a request" do
    before do
        @ir = mock_model(InfoRequest, :url_title => 'myrequest', :title => 'My request')
        InfoRequest.stub!(:find_by_url_title).and_return(@ir)

        @user = mock_model(User)
        User.stub!(:find).and_return(@user)
    end

    it "should require login when making new track" do
        get :track_request, :url_title => @ir.url_title, :feed => 'track'
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
    end

    it "should make track and redirect if you are logged in " do
        old_count = TrackThing.count
        session[:user_id] = @user.id
        get :track_request, :url_title => @ir.url_title, :feed => 'track'
        TrackThing.count.should == old_count + 1
        response.should redirect_to(:controller => 'request', :action => 'show', :url_title => @ir.url_title)
    end

end

describe TrackController, "when sending alerts for a track" do
    integrate_views
    fixtures :info_requests, :outgoing_messages, :incoming_messages, :raw_emails, :info_request_events, :users, :track_things, :track_things_sent_emails
    include LinkToHelper # for main_url
  
    it "should send alerts" do
        TrackMailer.alert_tracks

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.body.should =~ /Alter your subscription/
        mail.to_addrs.to_s.should include(users(:silly_name_user).email)
        mail.body =~ /(http:\/\/.*\/c\/(.*))/
        mail_url = $1
        mail_token = $2
        
        mail.body.should_not =~ /&amp;/

        # Check subscription managing link
# XXX We can't do this, as it is redirecting to another control, so this is a
# functional test. Bah, I so don't care, bit of an obsessive constraint.
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
    end

end
 
describe TrackController, "when viewing RSS feed for a track" do
    integrate_views
    fixtures :info_requests, :outgoing_messages, :incoming_messages, :raw_emails, :info_request_events, :users, :track_things, :comments, :public_bodies

    before do
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

end
 

