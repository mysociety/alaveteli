require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminUserController, "when administering users" do
    integrate_views
    before do
        basic_auth_login @request
    end
  
    it "shows the index/list page" do
        get :index
    end

    it "searches for 'bob'" do
        get :list, :query => "bob"
        assigns[:admin_users].should == [ users(:bob_smith_user) ]
    end

    it "shows a user" do
        get :show, :id => users(:bob_smith_user)
    end
    
    it "logs in as another user" do
        get :login_as,  :id => users(:bob_smith_user).id
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'confirm', :email_token => post_redirect.email_token)
    end

    it "logs in as another user when already logged in as an admin" do
        session[:user_id] = users(:admin_user).id
        get :login_as,  :id => users(:bob_smith_user).id
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'confirm', :email_token => post_redirect.email_token)
        session[:user_id].should be_nil
    end
end

