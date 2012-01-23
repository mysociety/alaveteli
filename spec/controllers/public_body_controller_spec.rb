require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'json'

describe PublicBodyController, "when showing a body" do
    integrate_views
    fixtures :public_bodies, :public_body_translations, :public_body_versions, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :comments, :info_request_events, :track_things

    before(:each) do
        load_raw_emails_data(raw_emails)
        rebuild_xapian_index
    end

    it "should be successful" do
        get :show, :url_name => "dfh", :view => 'all'
        response.should be_success
    end

    it "should render with 'show' template" do
        get :show, :url_name => "dfh", :view => 'all'
        response.should render_template('show')
    end

    it "should assign the body" do
        get :show, :url_name => "dfh", :view => 'all'
        assigns[:public_body].should == public_bodies(:humpadink_public_body)
    end

    it "should assign the requests" do
        get :show, :url_name => "tgq", :view => 'all'
        assigns[:xapian_requests].results.count.should == 2
        get :show, :url_name => "tgq", :view => 'successful'
        assigns[:xapian_requests].results.count.should == 0
        get :show, :url_name => "dfh", :view => 'all'
        assigns[:xapian_requests].results.count.should == 1
    end

    it "should assign the body using different locale from that used for url_name" do
        PublicBody.with_locale(:es) do
            get :show, {:url_name => "dfh", :view => 'all'}
            assigns[:public_body].notes.should == "Baguette"
        end
    end

    it "should assign the body using same locale as that used in url_name" do
        PublicBody.with_locale(:es) do
            get :show, {:url_name => "edfh", :view => 'all'}
            assigns[:public_body].notes.should == "Baguette"
        end
    end

    it "should redirect use to the relevant locale even when url_name is for a different locale" do
        old_filters = ActionController::Routing::Routes.filters
        ActionController::Routing::Routes.filters = RoutingFilter::Chain.new

        get :show, {:url_name => "edfh", :view => 'all'}
        response.should redirect_to "http://test.host/body/dfh"

        ActionController::Routing::Routes.filters = old_filters
    end
 
    it "should redirect to newest name if you use historic name of public body in URL" do
        get :show, :url_name => "hdink", :view => 'all'
        response.should redirect_to(:controller => 'public_body', :action => 'show', :url_name => "dfh")
    end

    it "should redirect to lower case name if you use mixed case name in URL" do
        get :show, :url_name => "dFh", :view => 'all'
        response.should redirect_to(:controller => 'public_body', :action => 'show', :url_name => "dfh")
    end
end

describe PublicBodyController, "when listing bodies" do
    integrate_views
    fixtures :public_bodies, :public_body_translations, :public_body_versions, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :comments, :info_request_events, :track_things

    it "should be successful" do
        get :list
        response.should be_success
    end

    it "should list all bodies from default locale, even when there are no translations for selected locale" do
        PublicBody.with_locale(:en) do
            english_only = PublicBody.new(:name => 'English only',
                                          :short_name => 'EO',
                                          :request_email => 'english@flourish.org',
                                          :last_edit_editor => 'test',
                                          :last_edit_comment => '')
            english_only.save
        end
        PublicBody.with_locale(:es) do
            get :list
            assigns[:public_bodies].length.should == 3
        end
    end

    it "should list bodies in alphabetical order" do
        get :list

        response.should render_template('list')

        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body), public_bodies(:geraldine_public_body) ]
        assigns[:tag].should == "all"
        assigns[:description].should == ""
    end

    it "should support simple searching of bodies by title" do
        get :list, :public_body_query => 'quango'
        assigns[:public_bodies].should == [ public_bodies(:geraldine_public_body) ]
    end

    it "should support simple searching of bodies by notes" do
        get :list, :public_body_query => 'Albatross'
        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body) ]
    end

    it "should list bodies in alphabetical order with different locale" do
        I18n.default_locale = :es
        get :list
        response.should render_template('list')
        assigns[:public_bodies].should == [ public_bodies(:geraldine_public_body), public_bodies(:humpadink_public_body) ]
        assigns[:tag].should == "all"
        assigns[:description].should == ""
        I18n.default_locale = :en
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
        assigns[:public_bodies].count.should == 2

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

    fixtures :public_bodies, :public_body_translations, :public_body_versions, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :comments, :info_request_events, :track_things

    it "should be successful" do
        get :show, :url_name => "dfh", :format => "json", :view => 'all'

        pb = JSON.parse(response.body)
        pb.class.to_s.should == 'Hash'

        pb['url_name'].should == 'dfh'
        pb['notes'].should == 'An albatross told me!!!'
    end

end

describe PublicBodyController, "when doing type ahead searches" do
    fixtures :public_bodies, :public_body_translations, :public_body_versions, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :comments, :info_request_events, :track_things

    integrate_views

    it "should return nothing for the empty query string" do
        get :search_typeahead, :query => ""
        response.should render_template('public_body/_search_ahead')
        assigns[:xapian_requests].should be_nil
    end
    
    it "should return a body matching the given keyword, but not users with a matching description" do
        get :search_typeahead, :query => "Geraldine"
        response.should render_template('public_body/_search_ahead')
        response.body.should include('search_ahead')
        assigns[:xapian_requests].results.size.should == 1
        assigns[:xapian_requests].results[0][:model].name.should == public_bodies(:geraldine_public_body).name
    end

    it "should return all requests matching any of the given keywords" do
        get :search_typeahead, :query => "Geraldine Humpadinking"
        response.should render_template('public_body/_search_ahead')
        assigns[:xapian_requests].results.size.should == 2
        assigns[:xapian_requests].results[0][:model].name.should == public_bodies(:humpadink_public_body).name
        assigns[:xapian_requests].results[1][:model].name.should == public_bodies(:geraldine_public_body).name
    end

    it "should return requests matching the given keywords in any of their locales" do
        get :search_typeahead, :query => "baguette" # part of the spanish notes
        response.should render_template('public_body/_search_ahead')
        assigns[:xapian_requests].results.size.should == 1
        assigns[:xapian_requests].results[0][:model].name.should == public_bodies(:humpadink_public_body).name
    end

    it "should not return  matches for short words" do
        get :search_typeahead, :query => "b" 
        response.should render_template('public_body/_search_ahead')
        assigns[:xapian_requests].should be_nil
    end
end
