require File.dirname(__FILE__) + '/../spec_helper'

describe AdminUserController, "when administering users" do
    integrate_views
    fixtures :users
  
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

end

