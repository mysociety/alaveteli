require File.dirname(__FILE__) + '/../spec_helper'

describe AdminPublicBodyController, "when administering public bodies" do
    integrate_views
    fixtures :public_bodies
  
    it "show the index page" do
        get :index
    end

end
