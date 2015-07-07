# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminTrackController, "when administering tracks" do

    it "shows the index page" do
        get :index
    end
end
