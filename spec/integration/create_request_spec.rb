require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When creating requests" do
    it "should associate the request with the requestor, even if it is approved by an admin" do
        # This is a test for https://github.com/mysociety/alaveteli/issues/446

        params = { :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id,
            :title => "Why is your quango called Geraldine?", :tag_string => "" },
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1, :preview => 0
        }

        # Initially we are not logged in. Try to create a new request.
        post "/new", params
        # We expect to be redirected to the login page
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
        follow_redirect!
        response.should render_template("user/sign")

        # Now log in as an unconfirmed user.
        post "/profile/sign_in", :user_signin => {:email => users(:unconfirmed_user).email, :password => "jonespassword"}, :token => post_redirect.token
        # This will trigger a confirmation mail. Get the PostRedirect for later.
        response.should render_template("user/confirm")
        post_redirect = PostRedirect.get_last_post_redirect

        # Now log in as an admin user, then follow the confirmation link in the email that was sent to the unconfirmed user
        admin_user = users(:admin_user)
        admin_user.email_confirmed = true
        admin_user.save!
        post_via_redirect "/profile/sign_in", :user_signin => {:email => admin_user.email, :password => "jonespassword"}
        response.should be_success
        get "/c/" + post_redirect.email_token
        follow_redirect!
        response.location.should =~ %r(/request/(.+)/new)
        response.location =~ %r(/request/(.+)/new)
        url_title = $1
        info_request = InfoRequest.find_by_url_title(url_title)
        info_request.should_not be_nil

        # Make sure the request is still owned by the user who made it, not the admin who confirmed it
        info_request.user_id.should == users(:unconfirmed_user).id
    end
end
