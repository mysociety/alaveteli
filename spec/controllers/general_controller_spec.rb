require File.dirname(__FILE__) + '/../spec_helper'

describe GeneralController, "when showing the front page" do
    integrate_views
    fixtures :users

    it "should be successful" do
        get :frontpage
        response.should be_success
    end

    it "should have sign in/up link when not signed in" do
        get :frontpage
        response.should have_tag('a', "Sign in or sign up")
    end

    it "should have sign out link when signed in" do
        session[:user_id] = users(:bob_smith_user).id
        get :frontpage
        response.should have_tag('a', "Sign out")
    end
        

end


