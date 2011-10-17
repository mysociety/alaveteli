require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GeneralController, "when searching" do
    integrate_views
    fixtures [ :public_bodies,
               :public_body_translations,
               :users,
               :raw_emails,
               :info_requests,
               :info_request_events,
               :outgoing_messages,
               :incoming_messages,
               :comments ]

    before(:each) do
        load_raw_emails_data(raw_emails)
    end

    it "should render the front page successfully" do
        get :frontpage
        response.should be_success
    end

    it "should render the front page with default language" do
        get :frontpage
        response.should have_tag('html[lang="en"]')
    end

    it "should render the front page with default language" do
        old_default_locale = I18n.default_locale
        I18n.default_locale = "es"
        get :frontpage
        response.should have_tag('html[lang="es"]')
        I18n.default_locale = old_default_locale
    end

    it "should render the front page with default language and ignore the browser setting" do
        config = MySociety::Config.load_default()
        config['USE_DEFAULT_BROWSER_LANGUAGE'] = false
        accept_language = "en-GB,en-US;q=0.8,en;q=0.6"
        request.env['HTTP_ACCEPT_LANGUAGE'] = accept_language
        old_default_locale = I18n.default_locale
        I18n.default_locale = "es"
        get :frontpage
        response.should have_tag('html[lang="es"]')
        I18n.default_locale = old_default_locale
    end

    it "should render the front page with browser-selected language when there's no default set" do
        config = MySociety::Config.load_default()
        config['USE_DEFAULT_BROWSER_LANGUAGE'] = true
        accept_language = "es-ES,en-GB,en-US;q=0.8,en;q=0.6"
        request.env['HTTP_ACCEPT_LANGUAGE'] = accept_language
        get :frontpage
        response.should have_tag('html[lang="es"]')
        request.env['HTTP_ACCEPT_LANGUAGE'] = nil
    end

    it "doesn't raise an error when there's no user matching the one in the session" do
        session[:user_id] = 999
        get :frontpage
        response.should be_success
    end

    it "should redirect from search query URL to pretty URL" do
        post :search_redirect, :query => "mouse" # query hidden in POST parameters
        response.should redirect_to(:action => 'search', :combined => "mouse", :view => "requests") # URL /search/:query/all
    end

    describe "when using different locale settings" do 
        home_link_regex = /href=".*\/en"/
        it "should generate URLs with a locale prepended when there's more than one locale set" do
            ActionController::Routing::Routes.add_filters('conditionallyprependlocale')
            get :frontpage
            response.should have_text(home_link_regex)
        end

        it "should generate URLs without a locale prepended when there's only one locale set" do
            ActionController::Routing::Routes.add_filters('conditionallyprependlocale')
            old_available_locales =  FastGettext.default_available_locales
            available_locales = ['en']
            FastGettext.default_available_locales = available_locales
            I18n.available_locales = available_locales

            get :frontpage
            response.should_not have_text(home_link_regex)

            FastGettext.default_available_locales = old_available_locales
            I18n.available_locales = old_available_locales
        end
    end

    describe 'when using xapian search' do

      # rebuild xapian index after fixtures loaded
      before(:all) do
          rebuild_xapian_index
      end

      it "should find info request when searching for '\"fancy dog\"'" do
          get :search, :combined => ['"fancy dog"']
          response.should render_template('search')
          assigns[:xapian_requests].matches_estimated.should == 1
          assigns[:xapian_requests].results.size.should == 1
          assigns[:xapian_requests].results[0][:model].should == info_request_events(:useless_outgoing_message_event)

          assigns[:xapian_requests].words_to_highlight == ["fancy", "dog"]
      end

      it "should find public body and incoming message when searching for 'geraldine quango'" do
          get :search, :combined => ['geraldine quango']
          response.should render_template('search')

          assigns[:xapian_requests].matches_estimated.should == 1
          assigns[:xapian_requests].results.size.should == 1
          assigns[:xapian_requests].results[0][:model].should == info_request_events(:useless_incoming_message_event)

          assigns[:xapian_bodies].matches_estimated.should == 1
          assigns[:xapian_bodies].results.size.should == 1
          assigns[:xapian_bodies].results[0][:model].should == public_bodies(:geraldine_public_body)
      end

    end

    it "should filter results based on end of URL being 'all'" do
        get :search, :combined => ['"bob"', "all"]
        assigns[:xapian_requests].results.size.should == 2
        assigns[:xapian_users].results.size.should == 1
        assigns[:xapian_bodies].results.size.should == 0
    end

    it "should filter results based on end of URL being 'users'" do
        get :search, :combined => ['"bob"', "users"]
        assigns[:xapian_requests].should == nil
        assigns[:xapian_users].results.size.should == 1
        assigns[:xapian_bodies].should == nil
    end

    it "should filter results based on end of URL being 'requests'" do
        get :search, :combined => ['"bob"', "requests"]
        assigns[:xapian_requests].results.size.should == 2
        assigns[:xapian_users].should == nil
        assigns[:xapian_bodies].should == nil
    end

    it "should filter results based on end of URL being 'bodies'" do
        get :search, :combined => ['"quango"', "bodies"]
        assigns[:xapian_requests].should == nil
        assigns[:xapian_users].should == nil
        assigns[:xapian_bodies].results.size.should == 1        
    end

    it "should show help when searching for nothing" do
        get :search_redirect, :query => nil
        response.should render_template('search')
        assigns[:total_hits].should be_nil
        assigns[:query].should be_nil
    end


end

