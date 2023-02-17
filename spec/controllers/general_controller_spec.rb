require 'spec_helper'

RSpec.describe GeneralController do
  describe 'GET version' do
    let(:mock_stats) do
      double(to_json: { foo: 'x', bar: 'y' }.to_json)
    end

    before do
      expect(Statistics::General).to receive(:new).and_return(mock_stats)
      expect(mock_stats).to receive(:to_json).with(kind_of(Hash))
      get :version, params: {}, format: :json
    end

    it 'renders json stats about the install' do
      parsed_body = JSON.parse(response.body).symbolize_keys
      expect(parsed_body).to eq({ foo: 'x', bar: 'y' })
    end

    it 'responds as JSON' do
      expect(response.media_type).to eq('application/json')
    end
  end
end

RSpec.describe GeneralController, "when trying to show the blog" do
  it "should fail silently if the blog is returning an error" do
    allow(AlaveteliConfiguration).to receive(:blog_feed).
      and_return("http://blog.example.com")
    stub_request(:get, %r|blog.example.com|).to_return(status: 500)
    get :blog
    expect(response.status).to eq(200)
    expect(assigns[:blog_items].count).to eq(0)
  end
end

RSpec.describe GeneralController, 'when getting the blog feed' do

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
      expect {
        get :blog
      }.to raise_error(ActiveRecord::RecordNotFound)
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

RSpec.describe GeneralController, "when showing the frontpage" do

  render_views

  before do
    public_body = mock_model(PublicBody, name: "Example Public Body",
                             url_name: 'example_public_body')
    info_request = mock_model(InfoRequest, public_body: public_body,
                              title: 'Example Request',
                              url_title: 'example_request')
    info_request_event = mock_model(InfoRequestEvent, created_at: Time.zone.now,
                                    info_request: info_request,
                                    described_at: Time.zone.now,
                                    search_text_main: 'example text')
    xapian_result = double('xapian result', results: [{model: info_request_event}])
    allow(controller).to receive(:perform_search).and_return(xapian_result)
  end

  it "should render the front page successfully" do
    get :frontpage
    expect(response).to be_successful
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
    sign_in double(:user, id: 999, login_token: 'abc')
    get :frontpage
    expect(response).to be_successful
  end

  describe 'when using locales' do

    it "should use our test PO files rather than the application one" do
      get :frontpage, params: { locale: 'es' }
      expect(response.body).to match /XOXO/
    end

  end

  describe 'when handling logged-in users' do

    before do
      @user = FactoryBot.create(:user)
      sign_in @user
    end

    it 'should set a time to live on a non "remember me" session' do
      get :frontpage
      expect(response.body).to match @user.name
      expect(session[:ttl]).to be_within(1).of(Time.zone.now)
    end

    it 'should not set a time to live on a "remember me" session' do
      session[:remember_me] = true
      get :frontpage
      expect(response.body).to match @user.name
      expect(session[:ttl]).to be_nil
    end

    it 'should end a logged-in session whose ttl has expired' do
      session[:ttl] = Time.zone.now - 4.hours
      get :frontpage
      expect(session[:user_id]).to be_nil
    end

    it "should render the front page successfully with post_redirect if post_params is not set" do
      session[:post_redirect_token] = 'orphaned_token'
      get :frontpage, params: { post_redirect: 1 }
      expect(response).to be_successful
    end

  end

  describe 'when handling pro users' do
    before do
      @user = FactoryBot.create(:pro_user)
      sign_in @user
      allow(controller).to receive(:feature_enabled?).with(:alaveteli_pro).and_return(true)
    end

    it 'should redirect pro users to the pro dashboard' do
      get :frontpage
      expect(@response).to redirect_to alaveteli_pro_dashboard_path
    end
  end

end


RSpec.describe GeneralController, 'when using xapian search' do

  render_views

  # rebuild xapian index after fixtures loaded
  before(:each) do
    load_raw_emails_data
    update_xapian_index
  end

  it "should redirect from search query URL to pretty URL" do
    post :search_redirect, params: { query: "mouse" } # query hidden in POST parameters
    expect(response).to redirect_to(action: 'search', combined: "mouse", view: "all") # URL /search/:query/all
  end

  it "should find info request when searching for '\"fancy dog\"'" do
    get :search, params: { combined: '"fancy dog"' }
    expect(response).to render_template('search')
    expect(assigns[:xapian_requests].matches_estimated).to eq(1)
    expect(assigns[:xapian_requests].results.size).to eq(1)
    expect(assigns[:xapian_requests].results[0][:model]).to eq(info_request_events(:useless_outgoing_message_event))

    assigns[:xapian_requests].words_to_highlight == %w[fancy dog]
  end

  it "should find public body and incoming message when searching for 'geraldine quango'" do
    get :search, params: { combined: 'geraldine quango' }
    expect(response).to render_template('search')

    expect(assigns[:xapian_requests].matches_estimated).to eq(1)
    expect(assigns[:xapian_requests].results.size).to eq(1)
    expect(assigns[:xapian_requests].results[0][:model]).to eq(info_request_events(:useless_incoming_message_event))

    expect(assigns[:xapian_bodies].matches_estimated).to eq(1)
    expect(assigns[:xapian_bodies].results.size).to eq(1)
    expect(assigns[:xapian_bodies].results[0][:model]).to eq(public_bodies(:geraldine_public_body))
  end

  it "should filter results based on end of URL being 'all'" do
    get :search, params: { combined: "bob/all" }
    expect(assigns[:xapian_requests].results.map { |x| x[:model] }).to match_array([
      info_request_events(:useless_outgoing_message_event),
      info_request_events(:silly_outgoing_message_event),
      info_request_events(:useful_incoming_message_event),
      info_request_events(:another_useful_incoming_message_event),
    ])
    expect(assigns[:xapian_users].results.map { |x| x[:model] }).to eq([users(:bob_smith_user)])
    expect(assigns[:xapian_bodies].results).to eq([])
  end

  it "should filter results based on end of URL being 'users'" do
    get :search, params: { combined: "bob/users" }
    expect(assigns[:xapian_requests]).to eq(nil)
    expect(assigns[:xapian_users].results.map { |x| x[:model] }).to eq([users(:bob_smith_user)])
    expect(assigns[:xapian_bodies]).to eq(nil)
  end

  it 'should highlight words for a user-only request' do
    get :search, params: { combined: "bob/users" }
    expect(assigns[:highlight_words]).to eq([/\b(bob)\w*\b/iu, /\b(bob)\b/iu])
  end

  it 'should show spelling corrections for a user-only request' do
    get :search, params: { combined: "rob/users" }
    expect(assigns[:spelling_correction]).to eq('bob')
    expect(response.body).to include('did_you_mean')
  end

  it "should filter results based on end of URL being 'requests'" do
    get :search, params: { combined: "bob/requests" }
    expect(assigns[:xapian_requests].results.map { |x|x[:model] }).to match_array([
      info_request_events(:useless_outgoing_message_event),
      info_request_events(:silly_outgoing_message_event),
      info_request_events(:useful_incoming_message_event),
      info_request_events(:another_useful_incoming_message_event),
    ])
    expect(assigns[:xapian_users]).to eq(nil)
    expect(assigns[:xapian_bodies]).to eq(nil)
  end

  it "should filter results based on end of URL being 'bodies'" do
    get :search, params: { combined: "quango/bodies" }
    expect(assigns[:xapian_requests]).to eq(nil)
    expect(assigns[:xapian_users]).to eq(nil)
    expect(assigns[:xapian_bodies].results.map { |x|x[:model] }).to eq([public_bodies(:geraldine_public_body)])
  end

  it 'should prioritise direct matches of public body names' do
    FactoryBot.create(:public_body, :with_note,
                      name: 'Cardiff Business Technology Centre Limited',
                      note_body: 'Something cardiff council something else.')

    FactoryBot.create(:public_body, :with_note,
                      name: 'Cardiff and Vale of Glamorgan Health Council',
                      note_body: 'Another notes mentioning Cardiff Council.')

    FactoryBot.create(:public_body, name: 'Cardiff Council')

    update_xapian_index

    get :search, params: { query: 'cardiff council',
                           combined: 'cardiff council/bodies' }
    results = assigns[:xapian_bodies].results.map { |x| x[:model] }

    expect(results.first.name).to eq('Cardiff Council')
  end

  it 'should show "Browse all" link if there are no results for a search restricted to bodies' do
    get :search, params: { combined: "noresultsshouldbefound/bodies" }
    expect(response.body).to include('Browse all')
  end

  it "should show help when searching for nothing" do
    get :search_redirect, params: { query: nil }
    expect(response).to render_template('search')
    expect(assigns[:total_hits]).to be_nil
    expect(assigns[:query]).to be_nil
  end

  it "should not show unconfirmed users" do
    get :search, params: { combined: "unconfirmed/users" }
    expect(response).to render_template('search')
    expect(assigns[:xapian_users].results.map { |x|x[:model] }).to eq([])
  end

  it "should show newly-confirmed users" do
    u = users(:unconfirmed_user)
    u.email_confirmed = true
    u.save!
    update_xapian_index

    get :search, params: { combined: "unconfirmed/users" }
    expect(response).to render_template('search')
    expect(assigns[:xapian_users].results.map { |x|x[:model] }).to eq([u])
  end

  it "should show tracking links for requests-only searches" do
    get :search, params: { combined: "bob/requests" }
    expect(response.body).to include('Track this search')
  end

  it 'should not show high page offsets as these are extremely slow to generate' do
    expect {
      get :search, params: { combined: 'bob/all', page: 25 }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'should pass xapian error messages to flash and redirect to a blank search page' do
    error_text = "Your query was not quite right. QueryParserError: Syntax: <expression> AND <expression>"
    get :search, params: { combined: "test AND" }
    expect(flash[:error]).to eq(error_text)
    expect(response).to redirect_to(action: 'search', combined: "")
  end

  context "when passed a non-HTML request" do

    it "raises unknown format error" do
      expect do
        get :search, params: { combined: '"fancy dog"', format: :json }
      end.to raise_error ActionController::UnknownFormat
    end

    it "does not call the search" do
      expect(controller).not_to receive(:perform_search)
      begin
        get :search, params: { combined: '"fancy dog"', format: :json }
      rescue ActionController::UnknownFormat
        # noop
      end
    end

  end
end
