require File.dirname(__FILE__) + '/../spec_helper'

describe AdminTrackController, "when administering tracks" do
    integrate_views
    fixtures :track_things, :users
  
    it "shows the list page" do
        get :list
    end
end
