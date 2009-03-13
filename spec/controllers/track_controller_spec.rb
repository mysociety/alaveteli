require File.dirname(__FILE__) + '/../spec_helper'

describe TrackController, "when making a new track on a request" do
    integrate_views
    fixtures :info_requests, :outgoing_messages, :incoming_messages, :raw_emails, :info_request_events, :users
  
    it "should require login when making new track" do
        get :track_request, :url_title => info_requests(:fancy_dog_request).url_title, :feed => 'track'
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
    end

    it "should make track and redirect if you are logged in " do
        TrackThing.count.should == 2
        session[:user_id] = users(:bob_smith_user).id
        get :track_request, :url_title => info_requests(:fancy_dog_request).url_title, :feed => 'track'
        TrackThing.count.should == 3
        response.should redirect_to(:controller => 'request', :action => 'show', :url_title => info_requests(:fancy_dog_request).url_title)
    end

end

describe TrackController, "when sending alerts for a track" do
    integrate_views
    fixtures :info_requests, :outgoing_messages, :incoming_messages, :raw_emails, :info_request_events, :users, :track_things, :track_things_sent_emails
  
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
# XXX reenable this if we ever have a page manager in the track controller
#        session[:user_id].should be_nil
#        controller.test_code_redirect_by_email_token(mail_token, self) # XXX hack to avoid having to call User controller for email link
#        session[:user_id].should == users(:silly_name_user).id
#
#        response.should render_template('users/show')
#        assigns[:display_user].should == users(:silly_name_user)

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
    rebuild_xapian_index

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
 

