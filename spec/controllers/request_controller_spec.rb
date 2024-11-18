require 'spec_helper'

RSpec.describe RequestController, "when listing request categories" do
  it "should be successful" do
    get :index
    expect(response).to be_successful
  end

  it "should render with 'index' template" do
    get :index
    expect(response).to render_template('index')
  end

  it 'sets title based on page' do
    get :index
    expect(assigns[:title]).to eq('Browse requests by category')
  end
end

RSpec.describe RequestController, "when listing recent requests" do
  it "should be successful" do
    get :list, params: { view: 'all' }
    expect(response).to be_successful
  end

  it "should render with 'list' template" do
    get :list, params: { view: 'all' }
    expect(response).to render_template('list')
  end

  it "should return 404 for pages we don't want to serve up" do
    expect {
      get :list, params: { view: 'all', page: 100 }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "raise unknown format error" do
    expect { get :list, params: { view: "all", format: :json } }.to(
      raise_error ActionController::UnknownFormat
    )
  end

  it 'should not raise an error for a page param of less than zero, but should treat it as a param of 1' do
    expect { get :list, params: { view: 'all', page: "-1" } }.not_to raise_error
    expect(assigns[:page]).to eq(1)
  end

  it 'sets title based on page' do
    get :list, params: { view: 'all' }
    expect(assigns[:title]).to eq('Search requests')

    get :list, params: { view: 'all', page: 2 }
    expect(assigns[:title]).to eq('Search requests (page 2)')
  end

  it 'sets title based on if tag matches an request category' do
    FactoryBot.create(:category, :info_request,
                      title: 'Climate requests', category_tag: 'climate')

    update_xapian_index
    get :list, params: { view: 'all', tag: 'climate' }
    expect(assigns[:title]).to eq('Climate requests')
  end

  it 'sets title based on if tag does not match an request category' do
    update_xapian_index
    get :list, params: { view: 'all', tag: 'other' }
    expect(assigns[:title]).to eq('Found 0 requests tagged ‘other’')

    FactoryBot.create(:info_request, tag_string: 'other')
    update_xapian_index
    get :list, params: { view: 'all', tag: 'other' }
    expect(assigns[:title]).to eq('Found 1 request tagged ‘other’')
  end
end

RSpec.describe RequestController, "when showing one request" do
  render_views

  before(:each) do
    load_raw_emails_data
  end

  it "should be successful" do
    get :show, params: { url_title: 'why_do_you_have_such_a_fancy_dog' }
    expect(response).to be_successful
  end

  it "should render with 'show' template" do
    get :show, params: { url_title: 'why_do_you_have_such_a_fancy_dog' }
    expect(response).to render_template('show')
  end

  it "should assign the request" do
    get :show, params: { url_title: 'why_do_you_have_such_a_fancy_dog' }
    expect(assigns[:info_request]).to eq(info_requests(:fancy_dog_request))
  end

  it 'should return a 404 for GET requests to a malformed request URL' do
    expect {
      get :show, params: { url_title: '228%85' }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  context 'when the request has similar requests' do
    let(:info_request) { FactoryBot.create(:info_request) }
    let(:similar_requests) { double.as_null_object }
    let(:similar_more) { double.as_null_object }

    before do
      allow_any_instance_of(InfoRequest).
        to receive(:similar_requests).
        and_return([similar_requests, similar_more])

      get :show, params: { url_title: info_request.url_title }
    end

    it 'assigns similar_requests' do
      expect(assigns[:similar_requests]).to eq(similar_requests)
    end

    it 'assigns similar_more' do
      expect(assigns[:similar_more]).to eq(similar_more)
    end
  end

  context 'when the request has citations' do
    let(:info_request) { FactoryBot.create(:info_request) }

    let(:citations) do
      FactoryBot.create_list(:citation, 5, citable: info_request)
    end

    before { get :show, params: { url_title: info_request.url_title } }

    it 'assigns newest 3 citations' do
      expect(assigns[:citations]).to match_array(citations.reverse.take(3))
    end
  end

  context 'when the request does not have citations' do
    let(:info_request) { FactoryBot.create(:info_request) }

    before { get :show, params: { url_title: info_request.url_title } }

    it 'assigns an empty array of citations' do
      expect(assigns[:citations]).to be_empty
    end
  end

  describe "livery used", feature: :alaveteli_pro do
    let(:pro_user) { FactoryBot.create(:pro_user) }

    before { sign_in pro_user }

    context "when showing pros their own requests" do
      context "when the request is embargoed" do
        let(:info_request) do
          FactoryBot.create(:embargoed_request, user: pro_user)
        end

        it 'uses the pro livery' do
          get :show, params: { url_title: info_request.url_title }
          expect(assigns[:in_pro_area]).to be true
        end
      end

      context "when the request is not embargoed" do
        let(:info_request) do
          FactoryBot.create(:info_request, user: pro_user)
        end

        it "should not use the pro livery" do
          get :show, params: { url_title: info_request.url_title }
          expect(assigns[:in_pro_area]).to be false
        end
      end
    end

    context 'when a cancelled pro views their embargoed request' do
      before do
        pro_user.remove_role(:pro)
      end

      let(:info_request) do
        FactoryBot.create(:embargoed_request, user: pro_user)
      end

      it 'uses the pro livery' do
        get :show, params: { url_title: info_request.url_title }
        expect(assigns[:in_pro_area]).to be true
      end
    end

    context "when showing pros a someone else's request" do
      it "should not user the pro livery" do
        get :show, params: { url_title: 'why_do_you_have_such_a_fancy_dog' }
        expect(assigns[:in_pro_area]).to be false
      end
    end
  end

  context 'when the request is embargoed' do
    it 'raises ActiveRecord::RecordNotFound' do
      embargoed_request = FactoryBot.create(:embargoed_request)
      expect {
        get :show, params: { url_title: embargoed_request.url_title }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "doesn't even redirect from a numeric id" do
      embargoed_request = FactoryBot.create(:embargoed_request)
      expect {
        get :show, params: { url_title: embargoed_request.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'when showing an external request' do
    describe 'when viewing anonymously' do
      it 'should be successful' do
        sign_in nil
        get :show, params: { url_title: 'balalas' }
        expect(response).to be_successful
      end
    end

    describe 'when the request is being viewed by an admin' do
      def make_request
        sign_in users(:admin_user)
        get :show, params: { url_title: 'balalas' }
      end

      it 'should be successful' do
        make_request
        expect(response).to be_successful
      end
    end
  end

  describe 'when handling an update_status parameter' do
    describe 'when the request is external' do
      it 'should assign the "update status" flag to the view as falsey if the parameter is present' do
        get :show, params: { url_title: 'balalas', update_status: 1 }
        expect(assigns[:update_status]).to be_falsey
      end

      it 'should assign the "update status" flag to the view as falsey if the parameter is not present' do
        get :show, params: { url_title: 'balalas' }
        expect(assigns[:update_status]).to be_falsey
      end
    end

    it 'should assign the "update status" flag to the view as truthy if the parameter is present' do
      get :show, params: {
                   url_title: 'why_do_you_have_such_a_fancy_dog',
                   update_status: 1
                 }
      expect(assigns[:update_status]).to be_truthy
    end

    it 'should assign the "update status" flag to the view as falsey if the parameter is not present' do
      get :show, params: { url_title: 'why_do_you_have_such_a_fancy_dog' }
      expect(assigns[:update_status]).to be_falsey
    end

    it 'should require login' do
      sign_in nil
      get :show, params: {
                   url_title: 'why_do_you_have_such_a_fancy_dog',
                   update_status: 1
                 }
      expect(response).
        to redirect_to(signin_path(token: get_last_post_redirect.token))
    end

    it 'should work if logged in as the requester' do
      sign_in users(:bob_smith_user)
      get :show, params: {
                   url_title: 'why_do_you_have_such_a_fancy_dog',
                   update_status: 1
                 }
      expect(response).to render_template "request/show"
    end

    it 'should not work if logged in as not the requester' do
      sign_in users(:silly_name_user)
      get :show, params: {
                   url_title: 'why_do_you_have_such_a_fancy_dog',
                   update_status: 1
                 }
      expect(response).to render_template "user/wrong_user"
    end

    it 'should work if logged in as an admin user' do
      sign_in users(:admin_user)
      get :show, params: {
                   url_title: 'why_do_you_have_such_a_fancy_dog',
                   update_status: 1
                 }
      expect(response).to render_template "request/show"
    end
  end

  describe 'when params[:pro] is true and a pro user is logged in' do
    let(:pro_user) { FactoryBot.create(:pro_user) }

    before :each do
      sign_in pro_user
      get :show, params: {
                   url_title: 'why_do_you_have_such_a_fancy_dog',
                   pro: "1"
                 }
    end

    it "should set @in_pro_area to true" do
      expect(assigns[:in_pro_area]).to be true
    end

    it "should set @sidebar_template to the pro sidebar" do
      expect(assigns[:sidebar_template]).
        to eq("alaveteli_pro/info_requests/sidebar")
    end
  end

  describe 'when params[:pro] is not set' do
    before :each do
      get :show, params: { url_title: 'why_do_you_have_such_a_fancy_dog' }
    end

    it "should set @in_pro_area to false" do
      expect(assigns[:in_pro_area]).to be false
    end

    it "should set @sidebar_template to the normal sidebar" do
      expect(assigns[:sidebar_template]).to eq("sidebar")
    end
  end

  describe "@show_top_describe_state_form" do
    let(:pro_user) { FactoryBot.create(:pro_user) }
    let(:pro_request) { FactoryBot.create(:embargoed_request, user: pro_user) }

    context "when @in_pro_area is true" do
      it "is false" do
        with_feature_enabled(:alaveteli_pro) do
          sign_in pro_user
          get :show, params: {
                       url_title: pro_request.url_title,
                       pro: "1",
                       update_status: "1"
                     }
          expect(assigns[:show_top_describe_state_form]).to be false
        end
      end
    end

    context "when @in_pro_area is false" do
      context "and @update_status is false" do
        it "is false" do
          info_request = info_requests(:naughty_chicken_request)
          expect(info_request.awaiting_description).to be false
          get :show, params: { url_title: info_request.url_title }
          expect(assigns[:show_top_describe_state_form]).to be false
        end

        context "but the request is awaiting_description" do
          it "is true" do
            get :show, params: {
                         url_title: 'why_do_you_have_such_a_fancy_dog'
                       }
            expect(assigns[:show_top_describe_state_form]).to be true
          end
        end
      end

      context "and @update_status is true" do
        it "is true" do
          sign_in users(:bob_smith_user)
          info_request = info_requests(:naughty_chicken_request)
          expect(info_request.awaiting_description).to be false
          get :show, params: {
                       url_title: info_request.url_title,
                       update_status: "1"
                     }
          expect(assigns[:show_top_describe_state_form]).to be true
        end

        context "and the request is awaiting_description" do
          it "is true" do
            get :show, params: {
                         url_title: 'why_do_you_have_such_a_fancy_dog',
                         update_status: "1"
                       }
            expect(assigns[:show_top_describe_state_form]).to be true
          end
        end
      end
    end

    context "when there are no valid state transitions" do
      it "is false" do
        info_request = FactoryBot.create(:info_request)
        info_request.set_described_state('not_foi')
        get :show, params: { url_title: info_request.url_title }
        expect(assigns[:show_top_describe_state_form]).to be false
      end
    end
  end

  describe "@show_bottom_describe_state_form" do
    let(:pro_user) { FactoryBot.create(:pro_user) }
    let(:pro_request) { FactoryBot.create(:embargoed_request, user: pro_user) }

    context "when @in_pro_area is true" do
      it "is false" do
        with_feature_enabled(:alaveteli_pro) do
          sign_in pro_user
          get :show, params: {
                       url_title: pro_request.url_title,
                       pro: "1"
                     }
          expect(assigns[:show_bottom_describe_state_form]).to be false
        end
      end
    end

    context "when @in_pro_area is false" do
      context "and the request is awaiting_description" do
        it "is true" do
          get :show, params: { url_title: 'why_do_you_have_such_a_fancy_dog' }
          expect(assigns[:show_bottom_describe_state_form]).to be true
        end
      end

      context "and the request is not awaiting_description" do
        it "is false" do
          info_request = info_requests(:naughty_chicken_request)
          expect(info_request.awaiting_description).to be false
          get :show, params: { url_title: info_request.url_title }
          expect(assigns[:show_bottom_describe_state_form]).to be false
        end
      end
    end

    context "when there are no valid state transitions" do
      it "is false" do
        info_request = FactoryBot.create(:info_request)
        info_request.set_described_state('not_foi')
        get :show, params: { url_title: info_request.url_title }
        expect(assigns[:show_bottom_describe_state_form]).to be false
      end
    end
  end

  it "should set @state_transitions for the request" do
    info_request = FactoryBot.create(:info_request)
    expected_transitions = {
      pending: {
        "waiting_response" => "<strong>No response</strong> has been " \
          "received <small>(maybe there's just an acknowledgement)</small>",
        "waiting_clarification" => "<strong>Clarification</strong> has been " \
          "requested",
        "gone_postal" => "A response will be sent <strong>by postal " \
          "mail</strong>"
      },
      complete: {
        "not_held" => "The authority do <strong>not have</strong> the " \
          "information <small>(maybe they say who does)</small>",
        "partially_successful" => "<strong>Some of the information</strong> " \
          "has been sent ",
        "successful" => "<strong>All the information</strong> has been sent",
        "rejected" => "The request has been <strong>refused</strong>"
      },
      other: {
        "error_message" => "An <strong>error message</strong> has been received"
      }
    }
    get :show, params: { url_title: info_request.url_title }
    expect(assigns(:state_transitions)).to eq(expected_transitions)
  end

  describe "showing update status actions" do
    let(:user) { FactoryBot.create(:user) }

    before do
      sign_in user
    end

    context "when the request is old and unclassified" do
      let(:info_request) { FactoryBot.create(:old_unclassified_request) }

      it "@show_owner_update_status_action should be false" do
        expect(info_request.is_old_unclassified?).to be true
        get :show, params: { url_title: info_request.url_title }
        expect(assigns[:show_owner_update_status_action]).to be false
      end

      it "@show_other_user_update_status_action should be true" do
        expect(info_request.is_old_unclassified?).to be true
        get :show, params: { url_title: info_request.url_title }
        expect(assigns[:show_other_user_update_status_action]).to be true
      end
    end

    context "when the request is not old and unclassified" do
      let(:info_request) { FactoryBot.create(:info_request) }

      it "@show_owner_update_status_action should be true" do
        get :show, params: { url_title: info_request.url_title }
        expect(assigns[:show_owner_update_status_action]).to be true
      end

      it "@show_other_user_update_status_action should be false" do
        get :show, params: { url_title: info_request.url_title }
        expect(assigns[:show_other_user_update_status_action]).to be false
      end
    end

    context "when there are no state_transitions" do
      let(:info_request) { FactoryBot.create(:info_request) }

      before do
        info_request.set_described_state('not_foi')
      end

      it "should hide all status update options" do
        get :show, params: { url_title: info_request.url_title }
        expect(assigns[:show_owner_update_status_action]).to be false
        expect(assigns[:show_other_user_update_status_action]).to be false
      end
    end
  end

  context 'when the request author is banned' do
    let(:user) { FactoryBot.create(:user, :banned) }
    let(:info_request) { FactoryBot.create(:info_request, user: user) }

    before do
      user.create_profile_photo!(data: load_file_fixture('parrot.png'))
    end

    it 'does not show the profile_photo' do
      get :show, params: { url_title: info_request.url_title }
      expect(assigns[:show_profile_photo]).to eq(false)
    end
  end
end

RSpec.describe RequestController, 'when handling prominence' do
  def expect_hidden(hidden_template)
    expect(response.media_type).to eq('text/html')
    expect(response).to render_template(hidden_template)
    expect(response.code).to eq('403')
  end

  let(:info_request) do
    FactoryBot.create(:info_request_with_pdf_attachment, prominence: prominence)
  end

  context 'when the request is hidden' do
    let(:prominence) { 'hidden' }

    it 'does not show the request if not logged in' do
      get :show, params: { url_title: info_request.url_title }
      expect_hidden('hidden')
    end

    it 'does not show the request even if logged in as their owner' do
      sign_in info_request.user
      get :show, params: { url_title: info_request.url_title }
      expect_hidden('hidden')
    end

    it 'does not show the request if requested using json' do
      sign_in info_request.user
      get :show, params: { url_title: info_request.url_title, format: 'json' }
      expect(response.code).to eq('403')
    end

    it 'shows the request if logged in as super user' do
      sign_in FactoryBot.create(:admin_user)
      get :show, params: { url_title: info_request.url_title }
      expect(response).to render_template('show')
    end
  end

  context 'when the request is requester_only' do
    let(:prominence) { 'requester_only' }

    it 'does not show the request if not logged in' do
      get :show, params: { url_title: info_request.url_title }
      expect_hidden('hidden')
    end

    it 'does not show the request if logged in but not the requester' do
      sign_in FactoryBot.create(:user)
      get :show, params: { url_title: info_request.url_title }
      expect_hidden('hidden')
    end

    it 'shows the request to the requester' do
      sign_in info_request.user
      get :show, params: { url_title: info_request.url_title }
      expect(response).to render_template('show')
    end

    it 'shows the request to an admin' do
      sign_in FactoryBot.create(:admin_user)
      get :show, params: { url_title: info_request.url_title }
      expect(response).to render_template('show')
    end
  end

  context 'when the request is backpage' do
    let(:prominence) { 'backpage' }

    it 'shows the request if not logged in' do
      get :show, params: { url_title: info_request.url_title }
      expect(response).to render_template('show')
    end

    it 'sets a noindex header' do
      get :show, params: { url_title: info_request.url_title }
      expect(response.headers['X-Robots-Tag']).to eq 'noindex'
    end
  end
end

# TODO: do this for invalid ids
#  it "should render 404 file" do
#    response.should render_template("#{Rails.root}/public/404.html")
#    response.headers["Status"].should == "404 Not Found"
#  end

RSpec.describe RequestController, "when searching for an authority" do
  # Whether or not sign-in is required for this step is configurable,
  # so we make sure we're logged in, just in case
  before do
    @user = users(:bob_smith_user)
    update_xapian_index
  end

  it "should return matching bodies" do
    sign_in @user
    get :select_authority, params: { query: "Quango" }

    expect(response).to render_template('select_authority')
    assigns[:xapian_requests].results.size == 1
    expect(assigns[:xapian_requests].results[0][:model].name).
      to eq(public_bodies(:geraldine_public_body).name)
  end

  it "remembers the search params" do
    sign_in @user
    search_params = {
      'query'  => 'Quango',
      'page'   => '1',
      'bodies' => '1'
    }

    get :select_authority, params: search_params

    flash_params = flash[:search_params].to_unsafe_h
    expect(flash_params).to eq(search_params)
  end

  describe 'when params[:pro] is true' do
    context "and a pro user is logged in " do
      let(:pro_user) { FactoryBot.create(:pro_user) }

      before do
        sign_in pro_user
      end

      it "should set @in_pro_area to true" do
        get :select_authority, params: { pro: "1" }
        expect(assigns[:in_pro_area]).to be true
      end

      it "should not redirect pros to the info request form for pros" do
        with_feature_enabled(:alaveteli_pro) do
          public_body = FactoryBot.create(:public_body)
          get :select_authority, params: { pro: "1" }
          expect(response).to be_successful
        end
      end
    end

    context "and a pro user is not logged in" do
      before do
        sign_in nil
      end

      it "should set @in_pro_area to false" do
        get :select_authority, params: { pro: "1" }
        expect(assigns[:in_pro_area]).to be false
      end

      it "should not redirect users to the info request form for pros" do
        with_feature_enabled(:alaveteli_pro) do
          public_body = FactoryBot.create(:public_body)
          get :select_authority, params: { pro: "1" }
          expect(response).to be_successful
        end
      end
    end
  end

  describe 'when params[:pro] is not set' do
    it "should set @in_pro_area to false" do
      get :select_authority
      expect(assigns[:in_pro_area]).to be false
    end

    it "should redirect pros to the info request form for pros" do
      with_feature_enabled(:alaveteli_pro) do
        pro_user = FactoryBot.create(:pro_user)
        public_body = FactoryBot.create(:public_body)
        sign_in pro_user
        get :select_authority
        expect(response).to redirect_to(new_alaveteli_pro_info_request_url)
      end
    end
  end
end

RSpec.describe RequestController, "when creating a new request" do
  render_views

  before do
    @user = users(:bob_smith_user)
    @body = public_bodies(:geraldine_public_body)
  end

  it "should redirect to front page if no public body specified" do
    get :new
    expect(response).to redirect_to(controller: 'general', action: 'frontpage')
  end

  it "should redirect to front page if no public body specified, when logged in" do
    sign_in @user
    get :new
    expect(response).to redirect_to(controller: 'general', action: 'frontpage')
  end

  it "should redirect 'bad request' page when a body has no email address" do
    @body.request_email = ""
    @body.save!
    get :new, params: { public_body_id: @body.id }
    expect(response).to render_template('new_bad_contact')
  end

  context "the outgoing message includes an email address" do
    context "there is no logged in user" do
      it "displays a flash error message without escaping the HTML" do
        post :new, params: {
                     info_request: {
                       public_body_id: @body.id,
                       title: "Test Request"
                     },
                     outgoing_message: { body: "me@here.com" },
                     submitted_new_request: 1,
                     preview: 1
                   }

        expect(response.body).to have_css('div#error p')
        expect(response.body).to_not have_content('<p>')
        expect(response.body).
          to have_content('You do not need to include your email')
      end
    end

    context "the user is logged in" do
      it "displays a flash error message without escaping the HTML" do
        sign_in @user
        post :new, params: {
                     info_request: {
                       public_body_id: @body.id,
                       title: "Test Request" },
                     outgoing_message: { body: "me@here.com" },
                     submitted_new_request: 1,
                     preview: 1
                   }

        expect(response.body).to have_css('div#error p')
        expect(response.body).to_not have_content('<p>')
        expect(response.body).
          to have_content('You do not need to include your email')
      end
    end
  end

  context "the outgoing message includes a postcode" do
    it 'displays an error message warning about the postcode' do
      post :new, params: {
                   info_request: {
                     public_body_id: @body.id,
                     title: "Test Request"
                   },
                   outgoing_message: { body: "SW1A 1AA" },
                   submitted_new_request: 1,
                   preview: 1
                 }

      expect(response.body).to have_content('Your request contains a postcode')
    end
  end

  context 'a network error occurs while sending the initial request' do
    def send_request
      sign_in @user
      post :new, params: {
                 info_request: {
                   public_body_id: @body.id,
                   title: 'Test request',
                   tag_string: ''
                 },
                 outgoing_message: {
                   body: 'This is a silly letter.'
                 },
                 submitted_new_request: 1,
                 preview: 0
               }
    end

    let(:request) { assigns[:info_request] }
    let(:outgoing_message) { request.reload.outgoing_messages.last }

    it_behaves_like 'NetworkSendErrors'
  end

  it "should redirect pros to the pro version" do
    with_feature_enabled(:alaveteli_pro) do
      pro_user = FactoryBot.create(:pro_user)
      public_body = FactoryBot.create(:public_body)
      sign_in pro_user
      get :new, params: { url_name: public_body.url_name }
      expected_url = new_alaveteli_pro_info_request_url(
        public_body: public_body.url_name)
      expect(response).to redirect_to(expected_url)
    end
  end

  it "should accept a public body parameter" do
    get :new, params: { public_body_id: @body.id }
    expect(assigns[:info_request].public_body).to eq(@body)
    expect(response).to render_template('new')
  end

  it 'assigns a default text for the request' do
    get :new, params: { public_body_id: @body.id }
    expect(assigns[:info_request].public_body).to eq(@body)
    expect(response).to render_template('new')
    default_message = <<-EOF.strip_heredoc
    Dear Geraldine Quango,

    Yours faithfully,
    EOF
    expect(assigns[:outgoing_message].body).to include(default_message.strip)
  end

  it 'allows the default text to be set via the default_letter param' do
    get :new, params: { url_name: @body.url_name, default_letter: "test" }
    default_message = <<-EOF.strip_heredoc
    Dear Geraldine Quango,

    test

    Yours faithfully,
    EOF
    expect(assigns[:outgoing_message].body).to include(default_message.strip)
  end

  it 'should display one meaningful error message when no message body is added' do
    post :new, params: {
                 info_request: { public_body_id: @body.id },
                 outgoing_message: { body: "" },
                 submitted_new_request: 1,
                 preview: 1
               }
    expect(assigns[:info_request].errors.full_messages).
      not_to include('Outgoing messages is invalid')
    expect(assigns[:outgoing_message].errors.full_messages).
      to include('Body Please enter your letter requesting information')
  end

  it "should give an error and render 'new' template when a summary isn't given" do
    post :new,
         params: {
           info_request: { public_body_id: @body.id },
           outgoing_message: {
             body: "This is a silly letter. It is too short to be interesting."
           },
           submitted_new_request: 1,
           preview: 1
         }
    expect(assigns[:info_request].errors[:title]).not_to be_nil
    expect(response).to render_template('new')
  end

  it "should redirect to sign in page when input is good and nobody is logged in" do
    params = {
      info_request: {
        public_body_id: @body.id,
        title: "Why is your quango called Geraldine?", tag_string: ""
      },
      outgoing_message: {
        body: "This is a silly letter. It is too short to be interesting."
      },
      submitted_new_request: 1, preview: 0
    }
    post :new, params: params
    expect(response).
      to redirect_to(signin_path(token: get_last_post_redirect.token))
    # post_redirect.post_params.should == params # TODO: get this working.
    # there's a : vs '' problem amongst others
  end

  it 'redirects to the frontpage if the action is sent the invalid
        public_body param' do
    post :new, params: {
                 info_request: {
                   public_body: @body.id,
                   title: 'Why Geraldine?',
                   tag_string: ''
                 },
                 outgoing_message: { body: 'This is a silly letter.' },
                 submitted_new_request: 1,
                 preview: 1
               }
    expect(response).to redirect_to frontpage_url
  end

  it "should show preview when input is good" do
    sign_in @user
    post :new, params: {
      info_request: {
        public_body_id: @body.id,
        title: "Why is your quango called Geraldine?",
        tag_string: ""
      },
      outgoing_message: {
        body: "This is a silly letter. It is too short to be interesting."
      },
      submitted_new_request: 1,
      preview: 1
    }
    expect(response).to render_template('preview')
  end

  it "should allow re-editing of a request" do
    post :new, params: {
      info_request: {
        public_body_id: @body.id,
        title: "Why is your quango called Geraldine?",
        tag_string: ""
      },
      outgoing_message: {
        body: "This is a silly letter. It is too short to be interesting."
      },
      submitted_new_request: 1,
      preview: 0,
      reedit: "Re-edit this request"
    }
    expect(response).to render_template('new')
  end

  it "re-editing preserves the message body" do
    post :new, params: {
      info_request: {
        public_body_id: @body.id,
        title: "Why is your quango called Geraldine?",
        tag_string: ""
      },
      outgoing_message: {
        body: "This is a silly letter. It is too short to be interesting."
      },
      submitted_new_request: 1,
      preview: 0,
      reedit: "Re-edit this request"
    }
    expect(assigns[:outgoing_message].body).
      to include('This is a silly letter. It is too short to be interesting.')
  end

  it "should create the request and outgoing message, and send the outgoing message by email, and redirect to request page when input is good and somebody is logged in" do
    sign_in @user
    post :new, params: {
      info_request: {
        public_body_id: @body.id,
        title: "Why is your quango called Geraldine?",
        tag_string: ""
      },
      outgoing_message: {
        body: "This is a silly letter. It is too short to be interesting."
      },
      submitted_new_request: 1,
      preview: 0
    }

    ir_array = InfoRequest.where(title: "Why is your quango called Geraldine?")
    expect(ir_array.size).to eq(1)
    ir = ir_array[0]
    expect(ir.outgoing_messages.size).to eq(1)
    om = ir.outgoing_messages[0]
    expect(om.body).
      to eq("This is a silly letter. It is too short to be interesting.")

    expect(deliveries.size).to eq(1)
    mail = deliveries.first
    expect(mail.body).
      to match(/This is a silly letter. It is too short to be interesting./)

    expect(response).to redirect_to show_request_url(ir.url_title)
  end

  it "sets the request_sent flash to true if successful" do
    sign_in @user
    post :new, params: {
      info_request: {
        public_body_id: @body.id,
        title: "Why is your quango called Geraldine?",
        tag_string: ""
      },
      outgoing_message: {
        body: "This is a silly letter. It is too short to be interesting."
      },
      submitted_new_request: 1,
      preview: 0
    }

    expect(flash[:request_sent]).to be true
  end

  it "should give an error if the same request is submitted twice" do
    sign_in @user

    # We use raw_body here, so white space is the same
    post :new, params: {
      info_request: {
        public_body_id: info_requests(:fancy_dog_request).public_body_id,
        title: info_requests(:fancy_dog_request).title
      },
      outgoing_message: {
        body: info_requests(:fancy_dog_request).outgoing_messages[0].raw_body
      },
      submitted_new_request: 1,
      preview: 0,
      mouse_house: 1
    }
    expect(response).to render_template('new')
  end

  it "should let you submit another request with the same title" do
    sign_in @user

    post :new, params: {
      info_request: {
        public_body_id: @body.id,
        title: "Why is your quango called Geraldine?",
        tag_string: ""
      },
      outgoing_message: {
        body: "This is a silly letter. It is too short to be interesting."
      },
      submitted_new_request: 1,
      preview: 0
    }

    post :new, params: {
      info_request: {
        public_body_id: @body.id,
        title: "Why is your quango called Geraldine?",
        tag_string: ""
      },
      outgoing_message: {
        body: "This is a sensible letter. It is too long to be boring."
      },
      submitted_new_request: 1,
      preview: 0
    }

    ir_array = InfoRequest.where(title: "Why is your quango called Geraldine?").
      order(:id)
    expect(ir_array.size).to eq(2)

    ir = ir_array[0]
    ir2 = ir_array[1]

    expect(ir.url_title).not_to eq(ir2.url_title)

    expect(response).to redirect_to show_request_url(ir2.url_title)
  end

  it 'should respect the rate limit' do
    # Try to create three requests in succession.
    # (The limit set in config/test.yml is two.)
    sign_in users(:robin_user)

    post :new, params: {
      info_request: {
        public_body_id: @body.id,
        title: "What is the answer to the ultimate question?",
        tag_string: ""
      },
      outgoing_message: {
        body: "Please supply the answer from your files."
      },
      submitted_new_request: 1,
      preview: 0
    }
    expect(response).to redirect_to(
      show_request_url('what_is_the_answer_to_the_ultima')
    )

    post :new, params: {
      info_request: {
        public_body_id: @body.id,
        title: "Why did the chicken cross the road?",
        tag_string: ""
      },
      outgoing_message: {
        body: "Please send me all the relevant documents you hold."
      },
      submitted_new_request: 1,
      preview: 0
    }
    expect(response).to redirect_to(
      show_request_url('why_did_the_chicken_cross_the_ro')
    )

    post :new, params: {
      info_request: {
        public_body_id: @body.id,
        title: "What's black and white and red all over?",
        tag_string: ""
      },
      outgoing_message: {
        body: "Please send all minutes of meetings and email records " \
                "that address this question."
      },
      submitted_new_request: 1,
      preview: 0
    }
    expect(response).to render_template('user/rate_limited')
  end

  it 'should ignore the rate limit for specified users' do
    # Try to create three requests in succession.
    # (The limit set in config/test.yml is two.)
    sign_in users(:robin_user)
    users(:robin_user).no_limit = true
    users(:robin_user).save!

    post :new, params: {
      info_request: {
        public_body_id: @body.id,
        title: "What is the answer to the ultimate question?",
        tag_string: ""
      },
      outgoing_message: {
        body: "Please supply the answer from your files."
      },
      submitted_new_request: 1,
      preview: 0
    }
    expect(response).to redirect_to(
      show_request_url('what_is_the_answer_to_the_ultima')
    )

    post :new, params: {
      info_request: {
        public_body_id: @body.id,
        title: "Why did the chicken cross the road?",
        tag_string: ""
      },
      outgoing_message: {
        body: "Please send me all the relevant documents you hold."
      },
      submitted_new_request: 1,
      preview: 0
    }
    expect(response).to redirect_to(
      show_request_url('why_did_the_chicken_cross_the_ro')
    )

    post :new, params: {
      info_request: {
        public_body_id: @body.id,
        title: "What's black and white and red all over?",
        tag_string: ""
      },
      outgoing_message: {
        body: "Please send all minutes of meetings and email records " \
                "that address this question."
      },
      submitted_new_request: 1,
      preview: 0
    }
    expect(response).to redirect_to(
      show_request_url('whats_black_and_white_and_red_al')
    )
  end

  describe 'when rendering a reCAPTCHA' do
    context 'when new_request_recaptcha disabled' do
      before do
        allow(AlaveteliConfiguration).to receive(:new_request_recaptcha)
          .and_return(false)
      end

      it 'sets render_recaptcha to false' do
        post :new, params: {
          info_request: {
            public_body_id: @body.id,
            title: "What's black and white and red all over?",
            tag_string: ""
          },
          outgoing_message: { body: "Please send info" },
          submitted_new_request: 1,
          preview: 0
        }
        expect(assigns[:render_recaptcha]).to eq(false)
      end
    end

    context 'when new_request_recaptcha is enabled' do
      before do
        allow(AlaveteliConfiguration).to receive(:new_request_recaptcha)
          .and_return(true)
      end

      it 'sets render_recaptcha to true if there is no logged in user' do
        post :new, params: {
          info_request: {
            public_body_id: @body.id,
            title: "What's black and white and red all over?",
            tag_string: ""
          },
          outgoing_message: { body: "Please send info" },
          submitted_new_request: 1,
          preview: 0
        }
        expect(assigns[:render_recaptcha]).to eq(true)
      end

      it 'sets render_recaptcha to true if there is a logged in user who is not
            confirmed as not spam' do
        sign_in FactoryBot.create(:user, confirmed_not_spam: false)
        post :new, params: {
          info_request: {
            public_body_id: @body.id,
            title: "What's black and white and red all over?",
            tag_string: ""
          },
          outgoing_message: { body: "Please send info" },
          submitted_new_request: 1,
          preview: 0
        }
        expect(assigns[:render_recaptcha]).to eq(true)
      end

      it 'sets render_recaptcha to false if there is a logged in user who is
            confirmed as not spam' do
        sign_in FactoryBot.create(:user, confirmed_not_spam: true)
        post :new, params: {
          info_request: {
            public_body_id: @body.id,
            title: "What's black and white and red all over?",
            tag_string: ""
          },
          outgoing_message: { body: "Please send info" },
          submitted_new_request: 1,
          preview: 0
        }
        expect(assigns[:render_recaptcha]).to eq(false)
      end

      context 'when the reCAPTCHA information is not correct' do
        before do
          allow(controller).to receive(:verify_recaptcha).and_return(false)
        end

        let(:user) { FactoryBot.create(:user,
                                      confirmed_not_spam: false) }
        let(:body) { FactoryBot.create(:public_body) }

        it 'shows an error message' do
          sign_in user
          post :new, params: {
            info_request: {
              public_body_id: body.id,
              title: "Some request text",
              tag_string: ""
            },
            outgoing_message: {
              body: "Please supply the answer from your files."
            },
            submitted_new_request: 1,
            preview: 0
          }
          expect(flash[:error]).
            to eq('There was an error with the reCAPTCHA. Please try again.')
        end

        it 'renders the compose interface' do
          sign_in user
          post :new, params: {
            info_request: {
              public_body_id: body.id,
              title: "Some request text",
              tag_string: ""
            },
            outgoing_message: {
              body: "Please supply the answer from your files."
            },
            submitted_new_request: 1,
            preview: 0
          }
          expect(response).to render_template("new")
        end

        it 'allows the request if the user is confirmed not spam' do
          user.confirmed_not_spam = true
          user.save!
          sign_in user
          post :new, params: {
            info_request: {
              public_body_id: body.id,
              title: "Some request text",
              tag_string: ""
            },
            outgoing_message: {
              body: "Please supply the answer from your files."
            },
            submitted_new_request: 1,
            preview: 0
          }
          expect(response).to redirect_to(
            show_request_path('some_request_text')
          )
        end
      end
    end
  end

  context 'when the request subject line looks like spam' do
    let(:user) { FactoryBot.create(:user,
                                   confirmed_not_spam: false) }
    let(:body) { FactoryBot.create(:public_body) }

    context 'when given a string containing unicode characters' do
      it 'converts the string to ASCII' do
        allow(AlaveteliConfiguration).to receive(:block_spam_requests).
          and_return(true)
        sign_in user
        title = "▩█ -Free Ɓrazzers Password Hăck Premium Account List 2017 ᒬᒬ"
        post :new, params: {
          info_request: {
            public_body_id: body.id,
            title: title,
            tag_string: ""
          },
          outgoing_message: {
            body: "Please supply the answer."
          },
          submitted_new_request: 1,
          preview: 0
        }
        mail = deliveries.first
        expect(mail.subject).to match(/Spam request from user #{ user.id }/)
      end
    end

    context 'when enable_anti_spam is false and block_spam_requests is true' do
      # double check that block_spam_subject? is behaving as expected
      before do
        allow(AlaveteliConfiguration).to receive(:enable_anti_spam).
          and_return(false)
        allow(AlaveteliConfiguration).to receive(:block_spam_requests).
          and_return(true)
      end

      it 'sends an exception notification' do
        sign_in user
        post :new,
             params: {
               info_request: {
                 public_body_id: body.id,
                 title: "[HD] Watch Jason Bourne Online free MOVIE Full-HD",
                 tag_string: ""
               },
               outgoing_message: {
                 body: "Please supply the answer."
               },
               submitted_new_request: 1,
               preview: 0
             }
        mail = deliveries.first
        expect(mail.subject).to match(/Spam request from user #{ user.id }/)
      end
    end

    context 'when block_spam_subject? is true' do
      before do
        allow(@controller).to receive(:block_spam_subject?).and_return(true)
      end

      it 'sends an exception notification' do
        sign_in user
        post :new, params: {
          info_request: {
            public_body_id: body.id,
            title: "[HD] Watch Jason Bourne Online free MOVIE Full-HD",
            tag_string: ""
          },
          outgoing_message: {
            body: "Please supply the answer from your files."
          },
          submitted_new_request: 1,
          preview: 0
        }
        mail = deliveries.first
        expect(mail.subject).to match(/Spam request from user #{ user.id }/)
      end

      it 'shows an error message' do
        sign_in user
        post :new, params: {
          info_request: {
            public_body_id: body.id,
            title: "[HD] Watch Jason Bourne Online free MOVIE Full-HD",
            tag_string: ""
          },
          outgoing_message: {
            body: "Please supply the answer from your files."
          },
          submitted_new_request: 1,
          preview: 0
        }
        expect(flash[:error]).to eq(
          "Sorry, we're currently unable to send your request. " \
          "Please try again later."
        )
      end

      it 'renders the compose interface' do
        sign_in user
        post :new, params: {
          info_request: {
            public_body_id: body.id,
            title: "[HD] Watch Jason Bourne Online free MOVIE Full-HD",
            tag_string: ""
          },
          outgoing_message: {
            body: "Please supply the answer from your files."
          },
          submitted_new_request: 1,
          preview: 0
        }
        expect(response).to render_template("new")
      end

      it 'allows the request if the user is confirmed not spam' do
        user.confirmed_not_spam = true
        user.save!
        sign_in user
        post :new,
             params: {
               info_request: {
                 public_body_id: body.id,
                 title: "[HD] Watch Jason Bourne Online free MOVIE Full-HD",
                 tag_string: ""
               },
               outgoing_message: {
                 body: "Please supply the answer from your files."
               },
               submitted_new_request: 1,
               preview: 0
             }
        expect(response).to redirect_to(
          show_request_path('hd_watch_jason_bourne_online_fre')
        )
      end
    end

    context 'when block_spam_subject? is false' do
      before do
        allow(@controller).to receive(:block_spam_subject?).and_return(false)
      end

      it 'sends an exception notification' do
        sign_in user
        post :new, params: {
          info_request: {
            public_body_id: body.id,
            title: "[HD] Watch Jason Bourne Online free MOVIE Full-HD",
            tag_string: ""
          },
          outgoing_message: {
            body: "Please supply the answer from your files."
          },
          submitted_new_request: 1,
          preview: 0
        }
        mail = deliveries.first
        expect(mail.subject).to match(/Spam request from user #{ user.id }/)
      end

      it 'allows the request' do
        sign_in user
        post :new,
             params: {
               info_request: {
                 public_body_id: body.id,
                 title: "[HD] Watch Jason Bourne Online free MOVIE Full-HD",
                 tag_string: ""
               },
               outgoing_message: {
                 body: "Please supply the answer from your files."
               },
               submitted_new_request: 1,
               preview: 0
             }
        expect(response).to redirect_to(
          show_request_path('hd_watch_jason_bourne_online_fre')
        )
      end
    end
  end

  describe 'when the request is from an IP address in a blocked country' do
    let(:user) { FactoryBot.create(:user,
                                   confirmed_not_spam: false) }
    let(:body) { FactoryBot.create(:public_body) }

    before do
      allow(AlaveteliConfiguration).
        to receive(:restricted_countries).
        and_return('PH')
      allow(controller).to receive(:country_from_ip).and_return('PH')
    end

    context 'when block_restricted_country_ips? is true' do
      before do
        allow(@controller).
          to receive(:block_restricted_country_ips?).and_return(true)
      end

      it 'sends an exception notification' do
        sign_in user
        post :new, params: {
          info_request: {
            public_body_id: body.id,
            title: "Some request content",
            tag_string: ""
          },
          outgoing_message: {
            body: "Please supply the answer from your files."
          },
          submitted_new_request: 1,
          preview: 0
        }
        mail = deliveries.first
        expect(mail.subject).
          to match(/\(ip_in_blocklist\) from User##{ user.id }/)
      end

      it 'shows an error message' do
        sign_in user
        post :new, params: {
          info_request: {
            public_body_id: body.id,
            title: "Some request content",
            tag_string: ""
          },
          outgoing_message: {
            body: "Please supply the answer from your files."
          },
          submitted_new_request: 1,
          preview: 0
        }
        expect(flash[:error]).to eq(
          "Sorry, we're currently unable to send your request. " \
          "Please try again later."
        )
      end

      it 'renders the compose interface' do
        sign_in user
        post :new, params: {
          info_request: {
            public_body_id: body.id,
            title: "Some request content",
            tag_string: ""
          },
          outgoing_message: {
            body: "Please supply the answer from your files."
          },
          submitted_new_request: 1,
          preview: 0
        }
        expect(response).to render_template("new")
      end

      it 'allows the request if the user is confirmed not spam' do
        user.confirmed_not_spam = true
        user.save!
        sign_in user
        post :new, params: {
          info_request: {
            public_body_id: body.id,
            title: "Some request content",
            tag_string: ""
          },
          outgoing_message: {
            body: "Please supply the answer from your files."
          },
          submitted_new_request: 1,
          preview: 0
        }
        expect(response).to redirect_to(
          show_request_path('some_request_content')
        )
      end
    end

    context 'when block_restricted_country_ips? is false' do
      before do
        allow(@controller).
          to receive(:block_restricted_country_ips?).and_return(false)
      end

      it 'sends an exception notification' do
        sign_in user
        post :new, params: {
          info_request: {
            public_body_id: body.id,
            title: "Some request content",
            tag_string: ""
          },
          outgoing_message: {
            body: "Please supply the answer from your files."
          },
          submitted_new_request: 1,
          preview: 0
        }
        mail = deliveries.first
        expect(mail.subject).
          to match(/\(ip_in_blocklist\) from User##{ user.id }/)
      end

      it 'allows the request' do
        sign_in user
        post :new, params: {
          info_request: {
            public_body_id: body.id,
            title: "Some request content",
            tag_string: ""
          },
          outgoing_message: {
            body: "Please supply the answer from your files."
          },
          submitted_new_request: 1,
          preview: 0
        }
        expect(response).to redirect_to(
          show_request_path('some_request_content')
        )
      end
    end
  end
end

# These go with the previous set, but use mocks instead of fixtures.
# TODO harmonise these
RSpec.describe RequestController, "when making a new request" do
  before do
    @user = mock_model(User, id: 3481, name: 'Testy').as_null_object
    allow(@user).to receive(:get_undescribed_requests).and_return([])
    allow(@user).to receive(:can_file_requests?).and_return(true)
    allow(@user).to receive(:locale).and_return("en")
    allow(@user).to receive(:login_token).and_return('abc')
    allow(User).to receive(:find_by).with(id: @user.id, login_token: 'abc').
      and_return(@user)
    @body = FactoryBot.create(:public_body, name: 'Test Quango')
  end

  it "should allow you to have one undescribed request" do
    allow(@user).to receive(:get_undescribed_requests).and_return([ 1 ])
    sign_in @user
    get :new, params: { public_body_id: @body.id }
    expect(response).to render_template('new')
  end

  it "should fail if more than one request undescribed" do
    allow(@user).to receive(:get_undescribed_requests).and_return([ 1, 2 ])
    sign_in @user
    get :new, params: { public_body_id: @body.id }
    expect(response).to render_template('new_please_describe')
  end

  it "should fail if user is banned" do
    allow(@user).to receive(:can_file_requests?).and_return(false)
    allow(@user).
      to receive(:exceeded_limit?).with(:info_requests).and_return(false)
    expect(@user).to receive(:can_fail_html).and_return('FAIL!')
    sign_in @user
    get :new, params: { public_body_id: @body.id }
    expect(response).to render_template('user/banned')
  end
end

RSpec.describe RequestController, "when viewing comments" do
  render_views
  before(:each) do
    load_raw_emails_data
  end

  it "should link to the user who submitted it" do
    sign_in users(:bob_smith_user)
    get :show, params: { url_title: 'why_do_you_have_such_a_fancy_dog' }
    expect(response.body).to have_css("div#comment-1 h2") do |s|
      expect(s).to have_text(/Silly.*left an annotation/m)
      expect(s).not_to have_text(/You.*left an annotation/m)
    end
  end

  it "should link to the user who submitted to it, even if it is you" do
    sign_in users(:silly_name_user)
    get :show, params: { url_title: 'why_do_you_have_such_a_fancy_dog' }
    expect(response.body).to have_css("div#comment-1 h2") do |s|
      expect(s).to have_text(/Silly.*left an annotation/m)
      expect(s).not_to have_text(/You.*left an annotation/m)
    end
  end
end

RSpec.describe RequestController, "authority uploads a response from the web interface" do
  before(:each) do
    # domain after the @ is used for authentication of FOI officers, so to test
    # it, we need a user which isn't at localhost.
    @normal_user = User.new(
      name: "Mr. Normal",
      email: "normal-user@flourish.org",
      password: PostRedirect.generate_random_token
    )
    @normal_user.save!

    @foi_officer_user = User.new(
      name: "The Geraldine Quango",
      email: "geraldine-requests@localhost",
      password: PostRedirect.generate_random_token
    )
    @foi_officer_user.save!
  end

  context 'when the request is embargoed' do
    let(:embargoed_request) { FactoryBot.create(:embargoed_request) }

    it 'raises an ActiveRecord::RecordNotFound error' do
      expect {
        get :upload_response, params: { url_title: embargoed_request.url_title }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when user is signed out' do
    it 'redirect to the login page' do
      get :upload_response, params: {
        url_title: 'why_do_you_have_such_a_fancy_dog'
      }
      expect(response).
        to redirect_to(signin_path(token: get_last_post_redirect.token))
    end
  end

  it "should require login to view the form to upload" do
    @ir = info_requests(:fancy_dog_request)
    expect(@ir.public_body.is_foi_officer?(@normal_user)).to eq(false)
    sign_in @normal_user

    get :upload_response, params: {
      url_title: 'why_do_you_have_such_a_fancy_dog'
    }
    expect(response).to render_template('user/wrong_user')
  end

  context 'when the request is closed to responses' do
    let(:closed_request) do
      FactoryBot.create(:info_request, allow_new_responses_from: 'nobody')
    end
    it "should prevent uploads if closed to all responses" do
      sign_in @normal_user
      get :upload_response, params: { url_title: closed_request.url_title }
      expect(response).to render_template(
        'request/request_subtitle/allow_new_responses_from/_nobody'
      )
    end
  end

  it "should let you view upload form if you are an FOI officer" do
    @ir = info_requests(:fancy_dog_request)
    expect(@ir.public_body.is_foi_officer?(@foi_officer_user)).to eq(true)
    sign_in @foi_officer_user

    get :upload_response, params: {
      url_title: 'why_do_you_have_such_a_fancy_dog'
    }
    expect(response).to render_template('request/upload_response')
  end

  it "should prevent uploads if you are not a requester" do
    @ir = info_requests(:fancy_dog_request)
    incoming_before = @ir.incoming_messages.count
    sign_in @normal_user

    # post up a photo of the parrot
    parrot_upload = fixture_file_upload('parrot.png', 'image/png')
    post :upload_response, params: {
      url_title: 'why_do_you_have_such_a_fancy_dog',
      body: "Find attached a picture of a parrot",
      file_1: parrot_upload,
      submitted_upload_response: 1
    }
    expect(response).to render_template('user/wrong_user')
  end

  it "should prevent entirely blank uploads" do
    sign_in @foi_officer_user

    post :upload_response, params: {
      url_title: 'why_do_you_have_such_a_fancy_dog',
      body: "", submitted_upload_response: 1
    }
    expect(response).to render_template('request/upload_response')
    expect(flash[:error]).to match(/Please type a message/)
  end

  it 'should 404 for non existent requests' do
    expect {
      post :upload_response, params: { url_title: 'i_dont_exist' }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  # How do I test a file upload in rails?
  # http://stackoverflow.com/questions/1178587/how-do-i-test-a-file-upload-in-rails
  it "should let the authority upload a file" do
    @ir = info_requests(:fancy_dog_request)
    incoming_before = @ir.incoming_messages.count
    sign_in @foi_officer_user

    # post up a photo of the parrot
    parrot_upload = fixture_file_upload('parrot.png', 'image/png')
    post :upload_response, params: {
      url_title: 'why_do_you_have_such_a_fancy_dog',
      body: "Find attached a picture of a parrot",
      file_1: parrot_upload,
      submitted_upload_response: 1
    }

    expect(response).to redirect_to(
      action: 'show',
      url_title: 'why_do_you_have_such_a_fancy_dog'
    )
    expect(flash[:notice]).
      to match(/Thank you for responding to this FOI request/)

    # check there is a new attachment
    incoming_after = @ir.incoming_messages.count
    expect(incoming_after).to eq(incoming_before + 1)

    # check new attachment looks vaguely OK
    new_im = @ir.incoming_messages[-1]
    expect(new_im.get_main_body_text_unfolded).
      to match(/Find attached a picture of a parrot/)
    attachments = new_im.get_attachments_for_display
    expect(attachments.size).to eq(1)
    expect(attachments[0].filename).to eq("parrot.png")
    expect(attachments[0].display_size).to eq("94K")
  end
end

RSpec.describe RequestController, "when showing JSON version for API" do
  before(:each) do
    load_raw_emails_data
  end

  it "should return data in JSON form" do
    get :show, params: {
      url_title: 'why_do_you_have_such_a_fancy_dog',
      format: 'json'
    }

    ir = JSON.parse(response.body)
    expect(ir.class.to_s).to eq('Hash')

    expect(ir['url_title']).to eq('why_do_you_have_such_a_fancy_dog')
    expect(ir['public_body']['url_name']).to eq('tgq')
    expect(ir['user']['url_name']).to eq('bob_smith')
  end
end

RSpec.describe RequestController, "when doing type ahead searches" do
  before :each do
    update_xapian_index
  end

  it 'can filter search results by public body' do
    get :search_typeahead, params: { q: 'boring', requested_from: 'dfh' }
    expect(assigns[:query]).to eq('requested_from:dfh boring')
  end

  it 'defaults to 25 results per page' do
    get :search_typeahead, params: { q: 'boring' }
    expect(assigns[:per_page]).to eq(25)
  end

  it 'can limit the number of searches returned' do
    get :search_typeahead, params: { q: 'boring', per_page: '1' }
    expect(assigns[:per_page]).to eq(1)
    expect(assigns[:xapian_requests].results.size).to eq(1)
  end
end

RSpec.describe RequestController, "when showing similar requests" do
  before do
    update_xapian_index
    load_raw_emails_data
  end

  let(:badger_request) { info_requests(:badger_request) }

  it "renders the 'similar' template" do
    get :similar, params: {
                    url_title: info_requests(:badger_request).url_title
                  }
    expect(response).to render_template("request/similar")
  end

  it 'assigns the request' do
    get :similar, params: {
                    url_title: info_requests(:badger_request).url_title
                  }
    expect(assigns[:info_request]).to eq(info_requests(:badger_request))
  end

  it "assigns a xapian object with similar requests" do
    get :similar, params: { url_title: badger_request.url_title }

    # Xapian seems to think *all* the requests are similar
    results = assigns[:xapian_object].results
    expected = InfoRequest.all.reject { |request| request == badger_request }
    expect(results.map { |result| result[:model].info_request })
      .to match_array(expected)
  end

  it "raises ActiveRecord::RecordNotFound for non-existent paths" do
    expect {
      get :similar, params: {
        url_title: "there_is_really_no_such_path_owNAFkHR"
      }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "raises ActiveRecord::RecordNotFound for pages beyond the last
      page we want to show" do
    expect {
      get :similar, params: {
        url_title: badger_request.url_title,
        page: 100
      }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'raises ActiveRecord::RecordNotFound if the request is embargoed' do
    badger_request.create_embargo(publish_at: Time.zone.now + 3.days)
    expect {
      get :similar, params: { url_title: badger_request.url_title }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end
end

RSpec.describe RequestController, "when the site is in read_only mode" do
  before do
    allow(AlaveteliConfiguration).
      to receive(:read_only).
      and_return("Down for maintenance")
  end

  it "redirects to the frontpage_url" do
    get :new
    expect(response).to redirect_to frontpage_url
  end

  it "shows a flash message to alert the user" do
    get :new
    expect(flash[:notice][:partial]).
      to eq "general/read_only_annotations"
  end

  context "when annotations are disabled" do
    before do
      allow(controller).
        to receive(:feature_enabled?).
        with(:annotations).
        and_return(false)
    end

    it "doesn't mention annotations in the flash message" do
      get :new
      expect(flash[:notice][:partial]).to eq "general/read_only"
    end
  end
end

RSpec.describe RequestController do
  describe 'GET #details' do
    let(:info_request) { FactoryBot.create(:info_request) }

    it 'renders the details template' do
      get :details, params: { url_title: info_request.url_title }
      expect(response).to render_template('details')
    end

    it 'assigns the info_request' do
      get :details, params: { url_title: info_request.url_title }
      expect(assigns[:info_request]).to eq(info_request)
    end

    context 'when the request is hidden' do
      before do
        info_request.prominence = 'hidden'
        info_request.save!
      end

      it 'returns a 403' do
        get :details, params: { url_title: info_request.url_title }
        expect(response.code).to eq("403")
      end

      it 'shows the hidden request template' do
        get :details, params: { url_title: info_request.url_title }
        expect(response).to render_template("request/hidden")
      end
    end

    context 'when the request is embargoed' do
      before do
        info_request.create_embargo(publish_at: Time.zone.now + 3.days)
      end

      it 'raises an ActiveRecord::RecordNotFound error' do
        expect {
          get :details, params: { url_title: info_request.url_title }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

RSpec.describe RequestController do
  describe 'GET #download_entire_request' do
    context 'when the request is embargoed' do
      let(:user) { FactoryBot.create(:user) }
      let(:pro_user) { FactoryBot.create(:pro_user) }
      let(:info_request) do
        FactoryBot.create(:embargoed_request, user: pro_user)
      end

      context 'and the user is not logged in' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            get :download_entire_request,
                params: { url_title: info_request.url_title }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'and the user is logged in but not the owner' do
        before do
          sign_in user
        end

        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            get :download_entire_request,
                params: { url_title: info_request.url_title }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'and the user is the owner' do
        before do
          sign_in pro_user
        end

        it 'allows the download' do
          get :download_entire_request,
              params: { url_title: info_request.url_title }
          expect(response).to be_successful
        end
      end
    end

    context 'when the request is unclassified' do
      it 'does not render the describe state form' do
        info_request = FactoryBot.create(:info_request)
        info_request.update(awaiting_description: true)
        info_request.expire
        sign_in info_request.user
        get :download_entire_request, params: {
          url_title: info_request.url_title
        }
        expect(assigns[:show_top_describe_state_form]).to eq(false)
        expect(assigns[:show_bottom_describe_state_form]).to eq(false)
        expect(assigns[:show_owner_update_status_action]).to eq(false)
        expect(assigns[:show_other_user_update_status_action]).to eq(false)
        expect(assigns[:show_profile_photo]).to eq(false)
      end
    end
  end
end

RSpec.describe RequestController do
  describe 'GET #show_request_event' do
    context 'when the event is an incoming message' do
      let(:event) { FactoryBot.create(:response_event) }

      it 'returns a 301 status' do
        get :show_request_event, params: { info_request_event_id: event.id }
        expect(response.status).to eq(301)
      end

      it 'redirects to the incoming message path' do
        get :show_request_event, params: { info_request_event_id: event.id }
        expect(response)
          .to redirect_to(incoming_message_path(event.incoming_message))
      end

      it 'raises ActiveRecord::RecordNotFound when the request is embargoed' do
        event.info_request.create_embargo(publish_at: Time.zone.now + 1.day)
        expect {
          get :show_request_event, params: { info_request_event_id: event.id }
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'when the event is an outgoing message' do
      let(:event) { FactoryBot.create(:sent_event) }

      it 'returns a 301 status' do
        get :show_request_event, params: { info_request_event_id: event.id }
        expect(response.status).to eq(301)
      end

      it 'redirects to the outgoing message path' do
        get :show_request_event, params: { info_request_event_id: event.id }
        expect(response)
          .to redirect_to(outgoing_message_path(event.outgoing_message))
      end

      it 'raises ActiveRecord::RecordNotFound when the request is embargoed' do
        event.info_request.create_embargo(publish_at: Time.zone.now + 1.day)
        expect {
          get :show_request_event, params: { info_request_event_id: event.id }
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'for any other kind of event' do
      let(:event) { FactoryBot.create(:info_request_event) }

      it 'returns a 301 status' do
        get :show_request_event, params: { info_request_event_id: event.id }
        expect(response.status).to eq(301)
      end

      it 'redirects to the request path' do
        get :show_request_event, params: { info_request_event_id: event.id }
        expect(response)
          .to redirect_to(show_request_path(event.info_request.url_title))
      end

      it 'raises ActiveRecord::RecordNotFound when the request is embargoed' do
        event.info_request.create_embargo(publish_at: Time.zone.now + 1.day)
        expect {
          get :show_request_event, params: { info_request_event_id: event.id }
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe 'GET #search_typeahead' do
    it "does not raise an error if there are no params" do
      expect {
        get :search_typeahead
      }.not_to raise_error
    end
  end
end
