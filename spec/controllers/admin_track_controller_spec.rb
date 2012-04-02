require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminTrackController, "when administering tracks" do
    integrate_views
  
    it "shows the list page" do
        get :list
    end
end
