require File.dirname(__FILE__) + '/../spec_helper'

describe BodyController, "when showing a body" do
    integrate_views
    fixtures :public_bodies, :public_body_versions
  
    it "should be successful" do
        get :show, :url_name => "dfh"
        response.should be_success
    end

    it "should render with 'show' template" do
        get :show, :url_name => "dfh"
        response.should render_template('show')
    end

    it "should assign the body" do
        get :show, :url_name => "dfh"
        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body) ]
    end

    it "should redirect to newest name if you use historic name of public body in URL" do
        get :show, :url_name => "hdink"
        response.should redirect_to(:controller => 'body', :action => 'show', :url_name => "dfh")
    end
    
    it "should redirect to lower case name if you use mixed case name in URL" do
        get :show, :url_name => "dFh"
        response.should redirect_to(:controller => 'body', :action => 'show', :url_name => "dfh")
    end
end

describe BodyController, "when listing bodies" do
    integrate_views
    fixtures :public_bodies, :public_body_versions
    
    it "should be successful" do
        get :list
        response.should be_success
    end

    it "should list bodies in alphabetical order" do
        get :list

        response.should render_template('list')

        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body), public_bodies(:geraldine_public_body) ]
        assigns[:tag].should == "all"
        assigns[:description].should == "all"
    end

    it "should list a tagged thing on the appropriate list page, and others on the other page, and all still on the all page" do
        public_bodies(:humpadink_public_body).tag_string = "foo local_council"

        get :list, :tag => "local_council"
        response.should render_template('list')
        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body) ]
        assigns[:tag].should == "local_council"
        assigns[:description].should == "Local councils"

        get :list, :tag => "other"
        response.should render_template('list')
        assigns[:public_bodies].should == [ public_bodies(:geraldine_public_body) ]

        get :list
        response.should render_template('list')
        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body), public_bodies(:geraldine_public_body) ]

    end

end



