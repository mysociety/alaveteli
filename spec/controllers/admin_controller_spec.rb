require File.dirname(__FILE__) + '/../spec_helper'

describe AdminController, "when viewing front page of admin interface" do
    integrate_views
  
    it "should render the front page" do
        get :index
        response.should render_template('index')
    end

    it "should render the front page with time line for last month" do
        get :index, :month => 1
        response.should render_template('index')
    end

    it "should render the front page with time line for all time" do
        get :index, :all => 1
        response.should render_template('index')
    end
end
