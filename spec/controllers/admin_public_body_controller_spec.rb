require File.dirname(__FILE__) + '/../spec_helper'

describe AdminPublicBodyController, "when administering public bodies" do
    integrate_views
    fixtures :public_bodies
  
    it "shows the index page" do
        get :index
    end

    it "shows a public body" do
        get :show, :id => 2
    end

    it "edits a public body" do
        get :edit, :id => 2
    end


end
