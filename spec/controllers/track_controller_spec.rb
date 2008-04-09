require File.dirname(__FILE__) + '/../spec_helper'

describe TrackController, "when making a new track on a request" do
    integrate_views
    fixtures :info_requests, :outgoing_messages, :incoming_messages, :info_request_events, :users
  
    it "should render with 'track_set' template" do
        get :track_request, :url_title => info_requests(:fancy_dog_request).url_title
        response.should render_template('track_set')
    end

    it "should assign the title" do
        get :track_request, :url_title => info_requests(:fancy_dog_request).url_title

        assigns[:title].should include("track the request")
    end

    it "should require login when making new track" do
        post :track_request, :url_title => info_requests(:fancy_dog_request).url_title,
            :track_thing => { :track_medium => "email_daily" }, 
            :submitted_track => 1
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
    end

    it "should make track and redirect if you are logged in " do
        TrackThing.count.should == 1
        session[:user_id] = users(:bob_smith_user).id
        post :track_request, :url_title => info_requests(:fancy_dog_request).url_title,
            :track_thing => { :track_medium => "email_daily" }, 
            :submitted_track => 1
        TrackThing.count.should == 2
        response.should redirect_to(:controller => 'request', :action => 'show', :url_title => info_requests(:fancy_dog_request).url_title)
    end

end

describe TrackController, "when sending alerts for a track" do
    integrate_views
    fixtures :info_requests, :outgoing_messages, :incoming_messages, :info_request_events, :users, :track_things, :track_things_sent_emails
  
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
 

