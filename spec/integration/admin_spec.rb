require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require "base64"

describe "When administering the site" do
    it "allows an admin to log in as another user" do
        # First log in as Joe Admin
        admin_user = users(:admin_user)
        admin_user.email_confirmed = true
        admin_user.save!
        post_via_redirect "/profile/sign_in", :user_signin => {:email => admin_user.email, :password => "jonespassword"}
        response.should be_success
        
        # Now fetch the "log in as" link to log in as Bob
        get_via_redirect "/admin/user/login_as/#{users(:bob_smith_user).id}", nil, {
          "Authorization" => "Basic " + Base64.encode64("#{AlaveteliConfiguration::admin_username}:#{AlaveteliConfiguration::admin_password}").strip
        }
        response.should be_success
        session[:user_id].should == users(:bob_smith_user).id
    end
end
