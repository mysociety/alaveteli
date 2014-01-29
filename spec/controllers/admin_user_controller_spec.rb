require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminUserController, "when administering users" do
    render_views
  
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

    # See also "allows an admin to log in as another user" in spec/integration/admin_spec.rb
end

describe AdminUserController, "when updating a user" do

    it "saves a change to 'can_make_batch_requests'" do
        user = FactoryGirl.create(:user)
        user.can_make_batch_requests?.should be_false
        post :update, {:id => user.id, :admin_user => {:can_make_batch_requests => '1',
                                                       :name => user.name,
                                                       :email => user.email,
                                                       :admin_level => user.admin_level,
                                                       :ban_text => user.ban_text,
                                                       :about_me => user.about_me,
                                                       :no_limit => user.no_limit}}
        flash[:notice].should == 'User successfully updated.'
        response.should be_redirect
        user = User.find(user.id)
        user.can_make_batch_requests?.should be_true
    end

end
