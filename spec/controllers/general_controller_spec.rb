require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'fakeweb'

describe GeneralController, "when trying to show the blog" do
    before (:each) do
        FakeWeb.clean_registry
    end
    after (:each) do
        FakeWeb.clean_registry
    end

    it "should fail silently if the blog is returning an error" do
        FakeWeb.register_uri(:get, %r|.*|, :body => "Error", :status => ["500", "Error"])
        get :blog
        response.status.should == 200
        assigns[:blog_items].count.should == 0
    end
end

describe GeneralController, 'when getting the blog feed' do

    before do
        AlaveteliConfiguration.stub!(:blog_feed).and_return("http://blog.example.com")
        # Don't call out to external url during tests
        controller.stub!(:quietly_try_to_open).and_return('')
    end

    it 'should add a lang param correctly to a url with no querystring' do
        get :blog
        assigns[:feed_url].should == "http://blog.example.com?lang=en"
    end

    it 'should add a lang param correctly to a url with an existing querystring' do
        AlaveteliConfiguration.stub!(:blog_feed).and_return("http://blog.example.com?alt=rss")
        get :blog
        assigns[:feed_url].should == "http://blog.example.com?alt=rss&lang=en"
    end

    it 'should parse an item from an example feed' do
        controller.stub!(:quietly_try_to_open).and_return(load_file_fixture("blog_feed.atom"))
        get :blog
        assigns[:blog_items].count.should == 1
    end

end

describe GeneralController, "when showing the frontpage" do

    render_views

    before do
      public_body = mock_model(PublicBody, :name => "Example Public Body",
                                           :url_name => 'example_public_body')
      info_request = mock_model(InfoRequest, :public_body => public_body,
                                             :title => 'Example Request',
                                             :url_title => 'example_request')
      info_request_event = mock_model(InfoRequestEvent, :created_at => Time.now,
                                                        :info_request => info_request,
                                                        :described_at => Time.now,
                                                        :search_text_main => 'example text')
      xapian_result = mock('xapian result', :results => [{:model => info_request_event}])
      controller.stub!(:perform_search).and_return(xapian_result)
    end

    it "should render the front page successfully" do
        get :frontpage
        response.should be_success
    end

    it "should render the front page with default language" do
        get :frontpage
        response.should have_selector('html[lang="en"]')
    end

    it "should render the front page with default language" do
        with_default_locale("es") do
            get :frontpage
            response.should have_selector('html[lang="es"]')
        end
    end

    it "should render the front page with default language and ignore the browser setting" do
        config = MySociety::Config.load_default()
        config['USE_DEFAULT_BROWSER_LANGUAGE'] = false
        accept_language = "en-GB,en-US;q=0.8,en;q=0.6"
        request.env['HTTP_ACCEPT_LANGUAGE'] = accept_language
        with_default_locale("es") do
            get :frontpage
            response.should have_selector('html[lang="es"]')
        end
    end

    it "should render the front page with browser-selected language when there's no default set" do
        config = MySociety::Config.load_default()
        config['USE_DEFAULT_BROWSER_LANGUAGE'] = true
        accept_language = "es-ES,en-GB,en-US;q=0.8,en;q=0.6"
        request.env['HTTP_ACCEPT_LANGUAGE'] = accept_language
        get :frontpage
        response.should have_selector('html[lang="es"]')
        request.env['HTTP_ACCEPT_LANGUAGE'] = nil
    end

    it "doesn't raise an error when there's no user matching the one in the session" do
        session[:user_id] = 999
        get :frontpage
        response.should be_success
    end

    describe 'when using locales' do

        it "should use our test PO files rather than the application one" do
            get :frontpage, :locale => 'es'
            response.body.should match /XOXO/
        end

    end

end
describe GeneralController, "when showing the front page with fixture data" do

    describe 'when constructing the list of recent requests' do

        before(:each) do
            get_fixtures_xapian_index
        end

        describe 'when there are fewer than five successful requests' do

            it 'should list the most recently sent and successful requests by the creation date of the
                request event' do
                # Make sure the newest response is listed first even if a request
                # with an older response has a newer comment or was reclassified more recently:
                # https://github.com/mysociety/alaveteli/issues/370
                #
                # This is a deliberate behaviour change, in that the
                # previous behaviour (showing more-recently-reclassified
                # requests first) was intentional.
                get :frontpage

                request_events = assigns[:request_events]
                previous = nil
                request_events.each do |event|
                    if previous
                        previous.created_at.should be >= event.created_at
                    end
                    ['sent', 'response'].include?(event.event_type).should be_true
                    if event.event_type == 'response'
                        ['successful', 'partially_successful'].include?(event.calculated_state).should be_true
                    end
                    previous = event
                end
            end
        end

        it 'should coalesce duplicate requests' do
            get :frontpage
            assigns[:request_events].map(&:info_request).select{|x|x.url_title =~ /^spam/}.length.should == 1
        end
    end

end

describe GeneralController, 'when using xapian search' do

    render_views

    # rebuild xapian index after fixtures loaded
    before(:each) do
        load_raw_emails_data
        get_fixtures_xapian_index
    end

    it "should redirect from search query URL to pretty URL" do
        post :search_redirect, :query => "mouse" # query hidden in POST parameters
        response.should redirect_to(:action => 'search', :combined => "mouse", :view => "all") # URL /search/:query/all
    end

    it "should find info request when searching for '\"fancy dog\"'" do
      get :search, :combined => '"fancy dog"'
      response.should render_template('search')
      assigns[:xapian_requests].matches_estimated.should == 1
      assigns[:xapian_requests].results.size.should == 1
      assigns[:xapian_requests].results[0][:model].should == info_request_events(:useless_outgoing_message_event)

      assigns[:xapian_requests].words_to_highlight == ["fancy", "dog"]
    end

    it "should find public body and incoming message when searching for 'geraldine quango'" do
      get :search, :combined => 'geraldine quango'
      response.should render_template('search')

      assigns[:xapian_requests].matches_estimated.should == 1
      assigns[:xapian_requests].results.size.should == 1
      assigns[:xapian_requests].results[0][:model].should == info_request_events(:useless_incoming_message_event)

      assigns[:xapian_bodies].matches_estimated.should == 1
      assigns[:xapian_bodies].results.size.should == 1
      assigns[:xapian_bodies].results[0][:model].should == public_bodies(:geraldine_public_body)
    end

    it "should filter results based on end of URL being 'all'" do
        get :search, :combined => "bob/all"
        assigns[:xapian_requests].results.map{|x| x[:model]}.should =~ [
            info_request_events(:useless_outgoing_message_event),
            info_request_events(:silly_outgoing_message_event),
            info_request_events(:useful_incoming_message_event),
            info_request_events(:another_useful_incoming_message_event),
        ]
        assigns[:xapian_users].results.map{|x| x[:model]}.should == [users(:bob_smith_user)]
        assigns[:xapian_bodies].results.should == []
    end

    it "should filter results based on end of URL being 'users'" do
        get :search, :combined => "bob/users"
        assigns[:xapian_requests].should == nil
        assigns[:xapian_users].results.map{|x| x[:model]}.should == [users(:bob_smith_user)]
        assigns[:xapian_bodies].should == nil
    end

    it 'should highlight words for a user-only request' do
      get :search, :combined => "bob/users"
      assigns[:highlight_words].should == ['bob']
    end

    it 'should show spelling corrections for a user-only request' do
      get :search, :combined => "rob/users"
      assigns[:spelling_correction].should == 'bob'
      response.body.should include('did_you_mean')
    end

    it "should filter results based on end of URL being 'requests'" do
        get :search, :combined => "bob/requests"
        assigns[:xapian_requests].results.map{|x|x[:model]}.should =~ [
            info_request_events(:useless_outgoing_message_event),
            info_request_events(:silly_outgoing_message_event),
            info_request_events(:useful_incoming_message_event),
            info_request_events(:another_useful_incoming_message_event),
        ]
        assigns[:xapian_users].should == nil
        assigns[:xapian_bodies].should == nil
    end

    it "should filter results based on end of URL being 'bodies'" do
        get :search, :combined => "quango/bodies"
        assigns[:xapian_requests].should == nil
        assigns[:xapian_users].should == nil
        assigns[:xapian_bodies].results.map{|x|x[:model]}.should == [public_bodies(:geraldine_public_body)]
    end

    it 'should show "Browse all" link if there are no results for a search restricted to bodies' do
        get :search, :combined => "noresultsshouldbefound/bodies"
        response.body.should include('Browse all')
    end

    it "should show help when searching for nothing" do
        get :search_redirect, :query => nil
        response.should render_template('search')
        assigns[:total_hits].should be_nil
        assigns[:query].should be_nil
    end

    it "should not show unconfirmed users" do
        get :search, :combined => "unconfirmed/users"
        response.should render_template('search')
        assigns[:xapian_users].results.map{|x|x[:model]}.should == []
    end

    it "should show newly-confirmed users" do
        u = users(:unconfirmed_user)
        u.email_confirmed = true
        u.save!
        update_xapian_index

        get :search, :combined => "unconfirmed/users"
        response.should render_template('search')
        assigns[:xapian_users].results.map{|x|x[:model]}.should == [u]
    end

    it "should show tracking links for requests-only searches" do
        get :search, :combined => "bob/requests"
        response.body.should include('Track this search')
    end

end
