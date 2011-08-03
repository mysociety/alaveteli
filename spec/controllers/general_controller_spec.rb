require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GeneralController, "when searching" do
    integrate_views
    fixtures [ :info_requests,
               :info_request_events,
               :public_bodies,
               :public_body_translations,
               :users,
               :raw_emails,
               :outgoing_messages,
               :incoming_messages,
               :comments ]

    it "should render the front page successfully" do
        get :frontpage
        response.should be_success
    end

    it "doesn't raise an error when there's no user matching the one in the session" do
        session[:user_id] = 999
        get :frontpage
        response.should be_success
    end


    it "should redirect from search query URL to pretty URL" do
        post :search_redirect, :query => "mouse" # query hidden in POST parameters
        response.should redirect_to(:action => 'search', :combined => "mouse") # URL /search/:query
    end

    describe "when using different locale settings" do 
        home_link_regex = /href=".*\/en"/
        it "should generate URLs with a locale prepended when there's more than one locale set" do
            ActionController::Routing::Routes.add_filters(['conditionallyprependlocale'])
            get :frontpage
            response.should have_text(home_link_regex)
        end

        it "should generate URLs without a locale prepended when there's only one locale set" do
            ActionController::Routing::Routes.add_filters(['conditionallyprependlocale'])
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

    it "should show help when searching for nothing" do
        get :search_redirect, :query => nil
        response.should render_template('search')
        assigns[:total_hits].should be_nil
        assigns[:query].should be_nil
    end


end

