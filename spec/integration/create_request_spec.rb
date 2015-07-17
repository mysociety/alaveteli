# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe "When creating requests" do

  it "should associate the request with the requestor, even if it is approved by an admin" do
    unregistered = without_login
    # This is a test for https://github.com/mysociety/alaveteli/issues/446
    unregistered.creates_request_unregistered
    post_redirect = PostRedirect.get_last_post_redirect
    # Now log in as an unconfirmed user.
    unregistered.post "/profile/sign_in", :user_signin => {:email => users(:unconfirmed_user).email, :password => "jonespassword"}, :token => post_redirect.token
    # This will trigger a confirmation mail. Get the PostRedirect for later.
    unregistered.response.body.should match('Now check your email!')
    post_redirect = PostRedirect.get_last_post_redirect


    # Now log in as an admin user, then follow the confirmation link in the email that was sent to the unconfirmed user
    confirm(:admin_user)
    admin = login(:admin_user)
    admin.get "/c/" + post_redirect.email_token
    admin.follow_redirect!
    admin.response.location.should =~ %r(/request/(.+)/new)
    admin.response.location =~ %r(/request/(.+)/new)
    url_title = $1
    info_request = InfoRequest.find_by_url_title(url_title)
    info_request.should_not be_nil

    # Make sure the request is still owned by the user who made it, not the admin who confirmed it
    info_request.user_id.should == users(:unconfirmed_user).id
  end

end
