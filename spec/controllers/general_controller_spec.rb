# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'fakeweb'

describe GeneralController do

  describe 'GET version' do

    it 'renders json stats about the install' do
      # Clean up fixtures
      InfoRequest.find_each(&:fully_destroy)
      Comment.find_each(&:fully_destroy)
      PublicBody.find_each(&:destroy)
      TrackThing.find_each(&:destroy)
      User.find_each(&:destroy)

      # Create some constant God models for other factories
      user = FactoryGirl.create(:user)
      body = FactoryGirl.create(:public_body)
      info_request = FactoryGirl.create(:info_request,
                                        :user => user, :public_body => body)
      default_args = { :info_request => info_request,
                       :public_body => body,
                       :user => user }

      # Create the other data we're checking
      FactoryGirl.create(:info_request, :user => user,
                                        :public_body => body,
                                        :prominence => 'hidden')
      FactoryGirl.create(:user, :email_confirmed => false)
      FactoryGirl.create(:visible_comment,
                         default_args.dup.slice!(:public_body))
      FactoryGirl.create(:hidden_comment,
                         default_args.dup.slice!(:public_body))
      FactoryGirl.create(:search_track, :tracking_user => user)
      FactoryGirl.create(:widget_vote,
                         default_args.dup.slice!(:user, :public_body))
      FactoryGirl.create(:internal_review_request,
                         default_args.dup.slice!(:user, :public_body))
      FactoryGirl.create(:internal_review_request,
                         :info_request => info_request, :prominence => 'hidden')
      FactoryGirl.create(:add_body_request,
                         default_args.dup.slice!(:info_request))
      event = FactoryGirl.create(:info_request_event,
                                 default_args.dup.slice!(:user, :public_body))
      FactoryGirl.create(:request_classification, :user => user,
                                                  :info_request_event => event)

      mock_git_commit = Digest::SHA1.hexdigest(Time.now.to_s)

      ApplicationController.
        any_instance.
          stub(:alaveteli_git_commit).
            and_return(mock_git_commit)

      expected = { :alaveteli_git_commit => mock_git_commit,
                   :alaveteli_version => ALAVETELI_VERSION,
                   :ruby_version => RUBY_VERSION,
                   :visible_public_body_count => 1,
                   :visible_request_count => 1,
                   :confirmed_user_count => 1,
                   :visible_comment_count => 1,
                   :track_thing_count => 1,
                   :widget_vote_count => 1,
                   :public_body_change_request_count => 1,
                   :request_classification_count => 1,
                   :visible_followup_message_count => 1 }

      get :version, :format => :json

      parsed_body = JSON.parse(response.body).symbolize_keys
      expect(parsed_body).to eq(expected)
    end

  end

end

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
    expect(response.status).to eq(200)
    expect(assigns[:blog_items].count).to eq(0)
  end
end

describe GeneralController, 'when getting the blog feed' do

  before do
    allow(AlaveteliConfiguration).to receive(:blog_feed).and_return("http://blog.example.com")
    # Don't call out to external url during tests
    allow(controller).to receive(:quietly_try_to_open).and_return('')
  end

  it 'should add a lang param correctly to a url with no querystring' do
    get :blog
    expect(assigns[:feed_url]).to eq("http://blog.example.com?lang=en")
  end

  it 'should add a lang param correctly to a url with an existing querystring' do
    allow(AlaveteliConfiguration).to receive(:blog_feed).and_return("http://blog.example.com?alt=rss")
    get :blog
    expect(assigns[:feed_url]).to eq("http://blog.example.com?alt=rss&lang=en")
  end

  it 'should parse an item from an example feed' do
    allow(controller).to receive(:quietly_try_to_open).and_return(load_file_fixture("blog_feed.atom"))
    get :blog
    expect(assigns[:blog_items].count).to eq(1)
  end

  context 'if no feed is configured' do

    before do
      allow(AlaveteliConfiguration).to receive(:blog_feed).and_return('')
    end

    it 'should raise an ActiveRecord::RecordNotFound error' do
      expect{ get :blog }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when the blog has entries' do

    render_views

    it 'should escape any javascript from the entries' do
      allow(controller).to receive(:quietly_try_to_open).and_return(load_file_fixture("blog_feed.atom"))
      get :blog
      expect(response.body).not_to include('<script>alert("exciting!")</script>')
    end

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
    xapian_result = double('xapian result', :results => [{:model => info_request_event}])
    allow(controller).to receive(:perform_search).and_return(xapian_result)
  end

  it "should render the front page successfully" do
    get :frontpage
    expect(response).to be_success
  end

  it "should render the front page with default language" do
    get :frontpage
    expect(response.body).to have_css('html[lang="en"]')
  end

  it "should render the front page with default language" do
    with_default_locale("es") do
      get :frontpage
      expect(response.body).to have_css('html[lang="es"]')
    end
  end

  it 'should generate a feed URL for successful requests' do
    get :frontpage
    expect(assigns[:feed_autodetect].size).to eq(1)
    successful_request_feed = assigns[:feed_autodetect].first
    expect(successful_request_feed[:title]).to eq('Successful requests')
  end


  it "should render the front page with default language and ignore the browser setting" do
    config = MySociety::Config.load_default
    config['USE_DEFAULT_BROWSER_LANGUAGE'] = false
    accept_language = "en-GB,en-US;q=0.8,en;q=0.6"
    request.env['HTTP_ACCEPT_LANGUAGE'] = accept_language
    with_default_locale("es") do
      get :frontpage
      expect(response.body).to have_css('html[lang="es"]')
    end
  end

  it "should render the front page with browser-selected language when there's no default set" do
    config = MySociety::Config.load_default
    config['USE_DEFAULT_BROWSER_LANGUAGE'] = true
    accept_language = "es-ES,en-GB,en-US;q=0.8,en;q=0.6"
    request.env['HTTP_ACCEPT_LANGUAGE'] = accept_language
    get :frontpage
    expect(response.body).to have_css('html[lang="es"]')
    request.env['HTTP_ACCEPT_LANGUAGE'] = nil
  end

  it "doesn't raise an error when there's no user matching the one in the session" do
    session[:user_id] = 999
    get :frontpage
    expect(response).to be_success
  end

  describe 'when using locales' do

    it "should use our test PO files rather than the application one" do
      get :frontpage, :locale => 'es'
      expect(response.body).to match /XOXO/
    end

  end

  describe 'when handling logged-in users' do

    before do
      @user = FactoryGirl.create(:user)
      session[:user_id] = @user.id
    end

    it 'should set a time to live on a non "remember me" session' do
      get :frontpage
      expect(response.body).to match @user.name
      expect(session[:ttl]).to be_within(1).of(Time.now)
    end

    it 'should not set a time to live on a "remember me" session' do
      session[:remember_me] = true
      get :frontpage
      expect(response.body).to match @user.name
      expect(session[:ttl]).to be_nil
    end

    it 'should end a logged-in session whose ttl has expired' do
      session[:ttl] = Time.now - 4.hours
      get :frontpage
      expect(session[:user_id]).to be_nil
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
    expect(response).to redirect_to(:action => 'search', :combined => "mouse", :view => "all") # URL /search/:query/all
  end

  it "should find info request when searching for '\"fancy dog\"'" do
    get :search, :combined => '"fancy dog"'
    expect(response).to render_template('search')
    expect(assigns[:xapian_requests].matches_estimated).to eq(1)
    expect(assigns[:xapian_requests].results.size).to eq(1)
    expect(assigns[:xapian_requests].results[0][:model]).to eq(info_request_events(:useless_outgoing_message_event))

    assigns[:xapian_requests].words_to_highlight == ["fancy", "dog"]
  end

  it "should find public body and incoming message when searching for 'geraldine quango'" do
    get :search, :combined => 'geraldine quango'
    expect(response).to render_template('search')

    expect(assigns[:xapian_requests].matches_estimated).to eq(1)
    expect(assigns[:xapian_requests].results.size).to eq(1)
    expect(assigns[:xapian_requests].results[0][:model]).to eq(info_request_events(:useless_incoming_message_event))

    expect(assigns[:xapian_bodies].matches_estimated).to eq(1)
    expect(assigns[:xapian_bodies].results.size).to eq(1)
    expect(assigns[:xapian_bodies].results[0][:model]).to eq(public_bodies(:geraldine_public_body))
  end

  it "should filter results based on end of URL being 'all'" do
    get :search, :combined => "bob/all"
    expect(assigns[:xapian_requests].results.map{|x| x[:model]}).to match_array([
      info_request_events(:useless_outgoing_message_event),
      info_request_events(:silly_outgoing_message_event),
      info_request_events(:useful_incoming_message_event),
      info_request_events(:another_useful_incoming_message_event),
    ])
    expect(assigns[:xapian_users].results.map{|x| x[:model]}).to eq([users(:bob_smith_user)])
    expect(assigns[:xapian_bodies].results).to eq([])
  end

  it "should filter results based on end of URL being 'users'" do
    get :search, :combined => "bob/users"
    expect(assigns[:xapian_requests]).to eq(nil)
    expect(assigns[:xapian_users].results.map{|x| x[:model]}).to eq([users(:bob_smith_user)])
    expect(assigns[:xapian_bodies]).to eq(nil)
  end

  it 'should highlight words for a user-only request' do
    get :search, :combined => "bob/users"
    expect(assigns[:highlight_words]).to eq([/\b(bob)\w*\b/iu,  /\b(bob)\b/iu])
  end

  it 'should show spelling corrections for a user-only request' do
    get :search, :combined => "rob/users"
    expect(assigns[:spelling_correction]).to eq('bob')
    expect(response.body).to include('did_you_mean')
  end

  it "should filter results based on end of URL being 'requests'" do
    get :search, :combined => "bob/requests"
    expect(assigns[:xapian_requests].results.map{|x|x[:model]}).to match_array([
      info_request_events(:useless_outgoing_message_event),
      info_request_events(:silly_outgoing_message_event),
      info_request_events(:useful_incoming_message_event),
      info_request_events(:another_useful_incoming_message_event),
    ])
    expect(assigns[:xapian_users]).to eq(nil)
    expect(assigns[:xapian_bodies]).to eq(nil)
  end

  it "should filter results based on end of URL being 'bodies'" do
    get :search, :combined => "quango/bodies"
    expect(assigns[:xapian_requests]).to eq(nil)
    expect(assigns[:xapian_users]).to eq(nil)
    expect(assigns[:xapian_bodies].results.map{|x|x[:model]}).to eq([public_bodies(:geraldine_public_body)])
  end

  it 'should show "Browse all" link if there are no results for a search restricted to bodies' do
    get :search, :combined => "noresultsshouldbefound/bodies"
    expect(response.body).to include('Browse all')
  end

  it "should show help when searching for nothing" do
    get :search_redirect, :query => nil
    expect(response).to render_template('search')
    expect(assigns[:total_hits]).to be_nil
    expect(assigns[:query]).to be_nil
  end

  it "should not show unconfirmed users" do
    get :search, :combined => "unconfirmed/users"
    expect(response).to render_template('search')
    expect(assigns[:xapian_users].results.map{|x|x[:model]}).to eq([])
  end

  it "should show newly-confirmed users" do
    u = users(:unconfirmed_user)
    u.email_confirmed = true
    u.save!
    update_xapian_index

    get :search, :combined => "unconfirmed/users"
    expect(response).to render_template('search')
    expect(assigns[:xapian_users].results.map{|x|x[:model]}).to eq([u])
  end

  it "should show tracking links for requests-only searches" do
    get :search, :combined => "bob/requests"
    expect(response.body).to include('Track this search')
  end

  it 'should not show high page offsets as these are extremely slow to generate' do
    expect {
      get :search, :combined => 'bob/all', :page => 25
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

end
