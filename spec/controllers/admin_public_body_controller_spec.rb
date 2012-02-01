require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminPublicBodyController, "when administering public bodies" do
    integrate_views

    before do
        username = MySociety::Config.get('ADMIN_USERNAME', '')
        password = MySociety::Config.get('ADMIN_PASSWORD', '')
        basic_auth_login @request
        
        @old_filters = ActionController::Routing::Routes.filters
        ActionController::Routing::Routes.filters = RoutingFilter::Chain.new
    end

    after do
        ActionController::Routing::Routes.filters = @old_filters
    end

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
        n = PublicBody.count
        post :create, { :public_body => { :name => "New Quango", :short_name => "", :tag_string => "blah", :request_email => 'newquango@localhost', :last_edit_comment => 'From test code' } }
        PublicBody.count.should == n + 1
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

    it "does not destroy a public body that has associated requests" do
        id = public_bodies(:humpadink_public_body).id
        n = PublicBody.count
        post :destroy, { :id => id }
        response.should redirect_to(:controller=>'admin_public_body', :action=>'show', :id => id)
        PublicBody.count.should == n
    end
    
    it "destroys a public body" do
        n = PublicBody.count
        post :destroy, { :id => public_bodies(:forlorn_public_body).id }
        response.should redirect_to(:controller=>'admin_public_body', :action=>'list')
        PublicBody.count.should == n - 1
    end

    it "sets a using_admin flag" do
        get :show, :id => 2
        session[:using_admin].should == 1
    end

    it "mass assigns tags" do
        n = PublicBody.count
        post :mass_tag_add, { :new_tag => "department", :table_name => "substring" }
        response.flash[:notice].should == "Added tag to table of bodies."
        response.should redirect_to(:action=>'list')
        PublicBody.find_by_tag("department").count.should == n
    end
end

describe AdminPublicBodyController, "when administering public bodies and paying attention to authentication" do

    integrate_views

    it "disallows non-authenticated users to do anything" do
        @request.env["HTTP_AUTHORIZATION"] = ""
        n = PublicBody.count
        post :destroy, { :id => 3 }
        response.code.should == "401"
        PublicBody.count.should == n
        session[:using_admin].should == nil
    end

    it "skips admin authorisation when no username/password set" do
        config = MySociety::Config.load_default()
        config['ADMIN_USERNAME'] = ''
        config['ADMIN_PASSWORD'] = ''
        @request.env["HTTP_AUTHORIZATION"] = ""

        n = PublicBody.count
        post :destroy, { :id => public_bodies(:forlorn_public_body).id }
        PublicBody.count.should == n - 1
        session[:using_admin].should == 1
    end
    
    it "skips admin authorisation when no username set" do
        config = MySociety::Config.load_default()
        config['ADMIN_USERNAME'] = ''
        config['ADMIN_PASSWORD'] = 'fuz'
        @request.env["HTTP_AUTHORIZATION"] = ""
        
        n = PublicBody.count
        post :destroy, { :id => public_bodies(:forlorn_public_body).id }
        PublicBody.count.should == n - 1
        session[:using_admin].should == 1
    end
    it "forces authorisation when password and username set" do
        config = MySociety::Config.load_default()
        config['ADMIN_USERNAME'] = 'biz'
        config['ADMIN_PASSWORD'] = 'fuz'
        @request.env["HTTP_AUTHORIZATION"] = ""
        n = PublicBody.count
        basic_auth_login(@request, "baduser", "badpassword")
        post :destroy, { :id => public_bodies(:forlorn_public_body).id }
        response.code.should == "401"
        PublicBody.count.should == n
        session[:using_admin].should == nil
    end



end

describe AdminPublicBodyController, "when administering public bodies with i18n" do
    integrate_views
  
    before do
        username = MySociety::Config.get('ADMIN_USERNAME', '')
        password = MySociety::Config.get('ADMIN_PASSWORD', '')
        basic_auth_login @request
    end

    it "shows the index page" do
        get :index
    end

    it "searches for 'humpa'" do
        get :index, {:query => "humpa", :locale => "es"}
        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body) ]
    end

    it "shows a public body" do
        get :show, {:id => 2, :locale => "es" }
    end

    it "edits a public body" do
        get :edit, {:id => 3, :locale => :en}
        
        # When editing a body, the controller returns all available translations
        assigns[:public_body].translation("es").name.should == 'El Department for Humpadinking'
        assigns[:public_body].name.should == 'Department for Humpadinking'
        response.should render_template('edit')
    end

    it "saves edits to a public body" do
        PublicBody.with_locale(:es) do
            pb = PublicBody.find(id=3)
            pb.name.should == "El Department for Humpadinking"
            post :update, { 
                :id => 3, 
                :public_body => { 
                    :name => "Department for Humpadinking", 
                    :short_name => "", 
                    :tag_string => "some tags", 
                    :request_email => 'edited@localhost', 
                    :last_edit_comment => 'From test code',
                    :translated_versions => {
                        3 => {:locale => "es", :name => "Renamed",:short_name => "", :request_email => 'edited@localhost'}
                        }
                    }
                }
            response.flash[:notice].should include('successful') 
        end

        pb = PublicBody.find(public_bodies(:humpadink_public_body).id)
        PublicBody.with_locale(:es) do
           pb.name.should == "Renamed"
        end
        PublicBody.with_locale(:en) do
           pb.name.should == "Department for Humpadinking"
        end
    end

    it "destroy a public body" do
        n = PublicBody.count
        post :destroy, { :id => public_bodies(:forlorn_public_body).id }
        PublicBody.count.should == n - 1
    end

end

describe AdminPublicBodyController, "when creating public bodies with i18n" do
    integrate_views
  
    before do
        username = MySociety::Config.get('ADMIN_USERNAME', '')
        password = MySociety::Config.get('ADMIN_PASSWORD', '')
        basic_auth_login @request
        
        @old_filters = ActionController::Routing::Routes.filters
        ActionController::Routing::Routes.filters = RoutingFilter::Chain.new
    end

    after do
        ActionController::Routing::Routes.filters = @old_filters
    end

    it "creates a new public body in one locale" do
        n = PublicBody.count
        post :create, { :public_body => { :name => "New Quango", :short_name => "", :tag_string => "blah", :request_email => 'newquango@localhost', :last_edit_comment => 'From test code' } }
        PublicBody.count.should == n + 1

        body = PublicBody.find_by_name("New Quango")
        response.should redirect_to(:controller=>'admin_public_body', :action=>'show', :id=>body.id)
    end

    it "creates a new public body with multiple locales" do
        n = PublicBody.count
        post :create, { 
            :public_body => { 
                :name => "New Quango", :short_name => "", :tag_string => "blah", :request_email => 'newquango@localhost', :last_edit_comment => 'From test code',
                :translated_versions => [{ :locale => "es", :name => "Mi Nuevo Quango", :short_name => "", :request_email => 'newquango@localhost' }]
                }
        }
        PublicBody.count.should == n + 1
        
        body = PublicBody.find_by_name("New Quango")
        body.translations.map {|t| t.locale.to_s}.sort.should == ["en", "es"]
        PublicBody.with_locale(:en) do
            body.name.should == "New Quango"
            body.url_name.should == "new_quango"
            body.first_letter.should == "N"
        end
        PublicBody.with_locale(:es) do
            body.name.should == "Mi Nuevo Quango"
            body.url_name.should == "mi_nuevo_quango"
            body.first_letter.should == "M"
        end
        
        response.should redirect_to(:controller=>'admin_public_body', :action=>'show', :id=>body.id)
    end
end
