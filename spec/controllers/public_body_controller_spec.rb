require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'json'

describe PublicBodyController, "when showing a body" do
    integrate_views
    fixtures :public_bodies, :public_body_translations, :public_body_versions

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
        assigns[:public_body].should == public_bodies(:humpadink_public_body)
    end

    it "should assign the body using different locale from that used for url_name" do
        get :show, {:url_name => "dfh", :locale => 'es'}
        assigns[:public_body].notes.should == "Baguette"
    end

    it "should assign the body using same locale as that used in url_name" do
        get :show, {:url_name => "edfh", :locale => 'es'}
        assigns[:public_body].notes.should == "Baguette"
    end

    it "should assign the body using same locale as that used in url_name even with wrongly set locale" do
        PublicBody.with_locale(:en) do 
            get :show, {:url_name => "edfh", :locale => 'es'}
            response.body.should include('Baguette')
        end
    end
 
    it "should redirect to newest name if you use historic name of public body in URL" do
        get :show, :url_name => "hdink"
        response.should redirect_to(:controller => 'public_body', :action => 'show', :url_name => "dfh")
    end

    it "should redirect to lower case name if you use mixed case name in URL" do
        get :show, :url_name => "dFh"
        response.should redirect_to(:controller => 'public_body', :action => 'show', :url_name => "dfh")
    end
end

describe PublicBodyController, "when listing bodies" do
    integrate_views
    fixtures :public_bodies, :public_body_translations, :public_body_versions

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

    it "should list bodies in alphabetical order with different locale" do
        get :list, :locale => "es"
        response.should render_template('list')

        assigns[:public_bodies].should == [ public_bodies(:geraldine_public_body), public_bodies(:humpadink_public_body) ]
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

    it "should list a machine tagged thing, should get it in both ways" do
        public_bodies(:humpadink_public_body).tag_string = "eats_cheese:stilton"

        get :list, :tag => "eats_cheese"
        response.should render_template('list')
        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body) ]
        assigns[:tag].should == "eats_cheese"

        get :list, :tag => "eats_cheese:jarlsberg"
        response.should render_template('list')
        assigns[:public_bodies].should == [ ]
        assigns[:tag].should == "eats_cheese:jarlsberg"

        get :list, :tag => "eats_cheese:stilton"
        response.should render_template('list')
        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body) ]
        assigns[:tag].should == "eats_cheese:stilton"


    end

end

describe PublicBodyController, "when showing JSON version for API" do

    fixtures :public_bodies, :public_body_translations

    it "should be successful" do
        get :show, :url_name => "dfh", :format => "json"

        pb = JSON.parse(response.body)
        pb.class.to_s.should == 'Hash'

        pb['url_name'].should == 'dfh'
        pb['notes'].should == 'An albatross told me!!!'
    end

end




