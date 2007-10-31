require File.dirname(__FILE__) + '/../spec_helper'

describe UserController, "when showing a user" do
    fixtures :users
  
    it "should be successful" do
        get :show, :simple_name => "bob_smith"
        response.should be_success
    end

    it "should render with 'show' template" do
        get :show, :simple_name => "bob_smith"
        response.should render_template('show')
    end

    it "should assign the user" do
        get :show, :simple_name => "bob-smith"
        assigns[:display_users].should == [ users(:bob_smith_user) ]
    end
    
    it "should assign the user for a more complex name" do
        get :show, :simple_name => "silly-emnameem"
        assigns[:display_users].should == [ users(:silly_name_user) ]
    end

    # XXX test for 404s when don't give valid name
end
