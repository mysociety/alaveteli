require File.dirname(__FILE__) + '/../spec_helper'

describe AdminPublicBodyController, "when administering public bodies" do
    integrate_views
    fixtures :public_bodies
  
    it "shows the index page" do
        get :index
    end

    it "searches for 'humpa'" do
        get :index, :query => "humpa"
        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body) ]
    end

    it "shows a public body" do
        get :show, :id => 2
    end

    it "creates a new public body" do
        PublicBody.count.should == 2
        post :create, { :public_body => { :name => "New Quango", :short_name => "", :tag_string => "blah", :request_email => 'newquango@localhost', :last_edit_comment => 'From test code' } }
        PublicBody.count.should == 3
    end

    it "edits a public body" do
        get :edit, :id => 2
    end

    it "saves edits to a public body" do
        public_bodies(:humpadink_public_body).name.should == "Department for Humpadinking"
        post :update, { :id => 3, :public_body => { :name => "Renamed", :short_name => "", :tag_string => "some tags", :request_email => 'edited@localhost', :last_edit_comment => 'From test code' } }
        response.flash[:notice].should include('successful')
        pb = PublicBody.find(public_bodies(:humpadink_public_body).id)
        pb.name.should == "Renamed"
    end

    it "destroy a public body" do
        PublicBody.count.should == 2
        post :destroy, { :id => 3 }
        PublicBody.count.should == 1
    end


end
