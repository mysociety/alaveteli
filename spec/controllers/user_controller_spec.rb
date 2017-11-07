# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserController do

  describe 'GET show' do

    let(:user) { FactoryGirl.create(:user) }

    it 'renders the show template' do
      get :show, :url_name => user.url_name
      expect(response).to render_template(:show)
    end

    it 'assigns the user' do
      get :show, url_name: user.url_name
      expect(assigns[:display_user]).to eq(user)
    end

    it 'should be successful' do
      get :show, url_name: user.url_name
      expect(response).to be_success
    end

    it 'raises a RecordNotFound for non-existent users' do
      user.destroy!
      expect { get :show, url_name: user.url_name }.
        to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises a RecordNotFound for unconfirmed users' do
      user = FactoryGirl.create(:user, email_confirmed: false)
      expect { get :show, url_name: user.url_name }.
        to raise_error(ActiveRecord::RecordNotFound)
    end

    # TODO: Use route_for or params_from to check /c/ links better
    # http://rspec.rubyforge.org/rspec-rails/1.1.12/classes/Spec/Rails/Example/
    # ControllerExampleGroup.html
    context 'when redirecting a show request to a canonical url' do

      it 'redirects to lower case name if given one with capital letters' do
        get :show, url_name: 'Bob_Smith'
        expect(response).to redirect_to(show_user_path(url_name: 'bob_smith'))
      end

      it 'redirects a long non-canonical name that has a numerical suffix, retaining the suffix' do
        get :show, url_name: 'Bob_SmithBob_SmithBob_SmithBob_S_2'
        expect(response).
          to redirect_to(show_user_path('bob_smithbob_smithbob_smithbob_s_2'))
      end

      it 'does not redirect a long canonical name that has a numerical suffix' do
        FactoryGirl.create(:user,
                           name: 'Bob Smith Bob Smith Bob Smith Bob Smith')
        FactoryGirl.create(:user,
                           name: 'Bob Smith Bob Smith Bob Smith Bob Smith')
        get :show, url_name: 'bob_smith_bob_smith_bob_smith_bo_2'
        expect(response).to be_success
      end

    end

    # Also doubles for when not logged in viewing another user's profile
    context 'when viewing a profile' do

      def make_request
        get :show, url_name: user.url_name, view: 'profile'
      end

      render_views

      it 'does not show requests or batch requests, but does show account options' do
        make_request

        expect(assigns[:show_profile]).to be true
        expect(assigns[:show_requests]).to be false
        expect(assigns[:show_batches]).to be false

        expect(response.body).
          not_to match(/Freedom of Information requests made by this person/)

        expect(response.body).
          to match(/change password, subscriptions and more/)
      end

    end

    # Also doubles for when not logged in viewing another user's requests
    context 'when viewing requests' do

      def make_request
        get :show, url_name: user.url_name, view: 'requests'
      end

      render_views

      it 'shows requests and batch requests, but does not show account options' do
        make_request

        expect(assigns[:show_profile]).to be false
        expect(assigns[:show_requests]).to be true
        expect(assigns[:show_batches]).to be true

        expect(response.body).
          to match(/Freedom of Information requests made by this person/)

        expect(response.body).
          not_to match(/change password, subscriptions and more/)
      end

      it 'does not show private requests' do
        user = FactoryGirl.create(:pro_user)
        FactoryGirl.create(:embargoed_request, user: user)
        update_xapian_index
        get :show, url_name: user.url_name, view: 'requests'
        expect(assigns[:private_requests]).to be_empty
      end

    end

    context 'when filtering requests' do

      before do
        load_raw_emails_data
        get_fixtures_xapian_index
      end

      it "searches the user's contributions" do
        user = users(:bob_smith_user)

        get :show, url_name: 'bob_smith'

        actual =
          assigns[:xapian_requests].results.map { |x| x[:model].info_request }

        expect(actual).to match_array(user.info_requests)
      end

      it 'filters by the given query' do
        user = users(:bob_smith_user)

        get :show, url_name: 'bob_smith', user_query: 'money'

        actual =
          assigns[:xapian_requests].results.map { |x| x[:model].info_request }

        expect(actual).to match_array([info_requests(:naughty_chicken_request),
                                       info_requests(:another_boring_request)])
      end

      it 'filters by the given query and request status' do
        user = users(:bob_smith_user)

        get :show, url_name: 'bob_smith',
                   user_query: 'money',
                   request_latest_status: 'waiting_response'

        actual =
          assigns[:xapian_requests].results.map{ |x| x[:model].info_request }

        expect(actual).to match_array([info_requests(:naughty_chicken_request)])
      end

    end

    context 'when logged in viewing your own profile' do

      def make_request
        get :show, url_name: user.url_name, view: 'profile'
      end

      render_views

      before do
        session[:user_id] = user.id
      end

      it 'does not show requests or batch requests, but does show account options' do
        make_request
        expect(response.body).
          not_to match(/Freedom of Information requests made by you/)
        expect(assigns[:show_batches]).to be false
        expect(response.body).to include('Change your password')
      end

    end

    context 'when logged in viewing your own requests' do

      def make_request
        get :show, url_name: user.url_name, view: 'requests'
      end

      render_views

      before do
        session[:user_id] = user.id
      end

      it "assigns the user's undescribed requests" do
        info_request = FactoryGirl.create(:info_request, user: user)

        allow_any_instance_of(User).
          to receive(:get_undescribed_requests).
            and_return([info_request])

        make_request

        expect(assigns[:undescribed_requests]).to eq([info_request])
      end

      it "assigns the user's track things" do
        search_track = FactoryGirl.create(:search_track, tracking_user: user)

        make_request

        expect(assigns[:track_things]).to eq([search_track])
      end

      it "assigns the user's grouped track things" do
        search_track = FactoryGirl.create(:search_track, tracking_user: user)

        make_request

        expect(assigns[:track_things_grouped]).
          to eq('search_query' => [search_track])
      end

      it 'shows requests, batch requests, but not account options' do
        make_request
        expect(response.body).
          to match(/Freedom of Information requests made by you/)
        expect(assigns[:show_batches]).to be true
        expect(response.body).not_to include('Change your password')
      end

      it 'does not include annotations of hidden requests in the count' do
        hidden_request =
          FactoryGirl.create(:info_request, prominence: 'hidden')
        comment1 = FactoryGirl.create(:visible_comment,
                                      info_request: hidden_request,
                                      user: user)
        FactoryGirl.create(:info_request_event,
                           event_type: 'comment',
                           comment: comment1,
                           info_request: hidden_request)

        shown_request = FactoryGirl.create(:info_request)
        comment2 = FactoryGirl.create(:visible_comment,
                                      info_request: shown_request,
                                      user: user)
        FactoryGirl.create(:info_request_event,
                           event_type: 'comment',
                           comment: comment2,
                           info_request: shown_request)

        expect(user.reload.comments.size).to eq(2)
        expect(user.reload.comments.visible.size).to eq(1)

        update_xapian_index
        make_request

        expect(response.body).to match(/Your 1 annotation/)
      end

      it 'shows private requests' do
        user = FactoryGirl.create(:pro_user)
        info_request = FactoryGirl.create(:embargoed_request, user: user)
        update_xapian_index
        session[:user_id] = user.id
        get :show, url_name: user.url_name, view: 'requests'
        expect(assigns[:private_requests]).to match_array([info_request])
      end

      it 'does not show hidden private requests' do
        user = FactoryGirl.create(:pro_user)
        info_request = FactoryGirl.create(:embargoed_request, user: user)
        FactoryGirl.create(:embargoed_request, user: user, prominence: 'hidden')
        update_xapian_index
        session[:user_id] = user.id
        get :show, url_name: user.url_name, view: 'requests'
        expect(assigns[:private_requests]).to match_array([info_request])
      end

    end

    context 'when logged in filtering your own requests' do

      before do
        session[:user_id] = user.id
      end

      it 'filters by the given query' do
        request_1 =
          FactoryGirl.create(:info_request, user: user, title: 'Some money?')
        FactoryGirl.create(:info_request, user: user, title: 'How many books?')
        update_xapian_index

        get :show, url_name: user.url_name,
                   view: 'requests',
                   user_query: 'money'

        actual =
          assigns[:xapian_requests].results.map { |x| x[:model].info_request }

        expect(actual).to match_array([request_1])
      end

      it 'filters private requests by the given query' do
        user = FactoryGirl.create(:pro_user)
        request_1 =
          FactoryGirl.
          create(:embargoed_request, user: user, title: 'Some money?')
        FactoryGirl.
          create(:embargoed_request, user: user, title: 'How many books?')
        update_xapian_index

        session[:user_id] = user.id

        get :show, url_name: user.url_name,
                   view: 'requests',
                   user_query: 'money'

        expect(assigns[:private_requests]).to match_array([request_1])
      end

      it 'filters by the given query and request status' do
        request_1 =
          FactoryGirl.create(:info_request, user: user, title: 'Some money?')
        FactoryGirl.create(:successful_request, user: user, title: 'More money')
        FactoryGirl.create(:info_request, user: user, title: 'How many books?')
        update_xapian_index

        get :show, url_name: user.url_name,
                   view: 'requests',
                   user_query: 'money',
                   request_latest_status: 'waiting_response'

        actual =
          assigns[:xapian_requests].results.map{ |x| x[:model].info_request }

        expect(actual).to match_array([request_1])
      end

      it 'filters private requests by the given query and request status' do
        request_1 =
          FactoryGirl.
          create(:embargoed_request, user: user, title: 'Some money?')
        FactoryGirl.
          create(:embargoed_request, user: user, title: 'How many books?')
        FactoryGirl.
          create(:embargoed_request, user: user, title: 'More money').
          set_described_state('successful')
        update_xapian_index

        get :show, url_name: user.url_name,
                   view: 'requests',
                   user_query: 'money',
                   request_latest_status: 'waiting_response'

        expect(assigns[:private_requests]).to match_array([request_1])
      end

    end

    context 'when logged in viewing other requests' do

      def make_request
        get :show, url_name: user.url_name, view: 'requests'
      end

      render_views

      before do
        session[:user_id] = FactoryGirl.create(:user).id
      end

      it "does not assign undescribed requests" do
        info_request = FactoryGirl.create(:info_request, user: user)

        allow_any_instance_of(User).
          to receive(:get_undescribed_requests).
            and_return([info_request])

        make_request

        expect(assigns[:undescribed_requests]).to be_nil
      end

      it "does not assign the user's track things" do
        search_track = FactoryGirl.create(:search_track, tracking_user: user)

        make_request

        expect(assigns[:track_things]).to be_nil
      end

      it "does not assign grouped track things" do
        search_track = FactoryGirl.create(:search_track, tracking_user: user)

        make_request

        expect(assigns[:track_things_grouped]).to be_nil
      end

      it 'shows requests, batch requests, but not account options' do
        make_request
        expect(response.body).
          to match(/Freedom of Information requests made by this person/)
        expect(assigns[:show_batches]).to be true
        expect(response.body).not_to include('Change your password')
      end

      it 'does not include annotations of hidden requests in the count' do
        hidden_request =
          FactoryGirl.create(:info_request, prominence: 'hidden')
        comment1 = FactoryGirl.create(:visible_comment,
                                      info_request: hidden_request,
                                      user: user)
        FactoryGirl.create(:info_request_event,
                           event_type: 'comment',
                           comment: comment1,
                           info_request: hidden_request)

        shown_request = FactoryGirl.create(:info_request)
        comment2 = FactoryGirl.create(:visible_comment,
                                      info_request: shown_request,
                                      user: user)
        FactoryGirl.create(:info_request_event,
                           event_type: 'comment',
                           comment: comment2,
                           info_request: shown_request)

        expect(user.reload.comments.size).to eq(2)
        expect(user.reload.comments.visible.size).to eq(1)

        update_xapian_index
        make_request

        expect(response.body).to match(/This person's 1 annotation/)
      end

      it 'does not show private requests' do
        pro_user = FactoryGirl.create(:pro_user)
        info_request = FactoryGirl.create(:embargoed_request, user: pro_user)
        update_xapian_index
        get :show, url_name: pro_user.url_name, view: 'requests'
        expect(assigns[:private_requests]).to be_empty
      end

      it 'does not show hidden private requests' do
        pro_user = FactoryGirl.create(:pro_user)
        info_request = FactoryGirl.create(:embargoed_request, user: pro_user)
        FactoryGirl.
          create(:embargoed_request, user: pro_user, prominence: 'hidden')
        update_xapian_index
        get :show, url_name: pro_user.url_name, view: 'requests'
        expect(assigns[:private_requests]).to be_empty
      end
    end

    context 'when logged in filtering other requests' do

      before do
        session[:user_id] = FactoryGirl.create(:user).id
      end

      it 'filters by the given query' do
        request_1 =
          FactoryGirl.create(:info_request, user: user, title: 'Some money?')
        FactoryGirl.create(:info_request, user: user, title: 'How many books?')
        update_xapian_index

        get :show, url_name: user.url_name,
                   view: 'requests',
                   user_query: 'money'

        actual =
          assigns[:xapian_requests].results.map { |x| x[:model].info_request }

        expect(actual).to match_array([request_1])
      end

      it 'does not show private requests when filtering by query' do
        pro_user = FactoryGirl.create(:pro_user)
        request_1 =
          FactoryGirl.
          create(:embargoed_request, user: pro_user, title: 'Some money?')
        FactoryGirl.
          create(:embargoed_request, user: pro_user, title: 'How many books?')
        update_xapian_index

        get :show, url_name: pro_user.url_name,
                   view: 'requests',
                   user_query: 'money'

        expect(assigns[:private_requests]).to be_empty
      end

      it 'filters by the given query and request status' do
        request_1 =
          FactoryGirl.create(:info_request, user: user, title: 'Some money?')
        FactoryGirl.create(:successful_request, user: user, title: 'More money')
        FactoryGirl.create(:info_request, user: user, title: 'How many books?')
        update_xapian_index

        get :show, url_name: user.url_name,
                   view: 'requests',
                   user_query: 'money',
                   request_latest_status: 'waiting_response'

        actual =
          assigns[:xapian_requests].results.map{ |x| x[:model].info_request }

        expect(actual).to match_array([request_1])
      end

      it 'does not show private requests when filtering by request status' do
        pro_user = FactoryGirl.create(:pro_user)
        request_1 =
          FactoryGirl.
          create(:embargoed_request, user: pro_user, title: 'Some money?')
        FactoryGirl.
          create(:embargoed_request, user: pro_user, title: 'How many books?')
        FactoryGirl.
          create(:embargoed_request, user: pro_user, title: 'More money').
          set_described_state('successful')
        update_xapian_index

        get :show, url_name: pro_user.url_name,
                   view: 'requests',
                   user_query: 'money',
                   request_latest_status: 'waiting_response'

        expect(assigns[:private_requests]).to be_empty
      end

    end

  end

  describe 'POST set_profile_photo' do

    context 'user is banned' do

      before(:each) do
        @user = FactoryGirl.create(:user, :ban_text => 'Causing trouble')
        session[:user_id] = @user.id
        @uploadedfile = fixture_file_upload("/files/parrot.png")

        post :set_profile_photo, :id => @user.id,
          :file => @uploadedfile,
          :submitted_draft_profile_photo => 1,
          :automatically_crop => 1
      end

      it 'redirects to the profile page' do
        expect(response).to redirect_to(set_profile_photo_path)
      end

      it 'renders an error message' do
        msg = 'Banned users cannot edit their profile'
        expect(flash[:error]).to eq(msg)
      end

    end

  end

  describe 'GET confirm' do

    context 'if the post redirect cannot be found' do

      it 'renders bad_token' do
        get :confirm, :email_token => ''
        expect(response).to render_template(:bad_token)
      end

    end

    context 'the post redirect circumstance is login_as' do

      before :each do
        @user = FactoryGirl.create(:user, :email_confirmed => false)
        @post_redirect =
          PostRedirect.
            create(:uri => '/', :user => @user, :circumstance => 'login_as')

        get :confirm, :email_token => @post_redirect.email_token
      end

      it 'confirms the post redirect user' do
        expect(@user.reload.email_confirmed).to eq(true)
      end

      it 'logs in as the post redirect user' do
        expect(session[:user_id]).to eq(@user.id)
      end

      it 'sets the user_circumstance to login_as' do
        expect(session[:user_circumstance]).to eq('login_as')
      end

      it 'redirects to the post redirect uri' do
        expect(response).to redirect_to('/?post_redirect=1')
      end

    end

    context 'the post redirect circumstance is change_password' do

      before :each do
        @user = FactoryGirl.create(:user)
        @post_redirect =
          PostRedirect.create(:uri => edit_password_change_path,
                              :user => @user,
                              :circumstance => 'change_password')

        get :confirm, :email_token => @post_redirect.email_token
      end

      it 'sets the change_password_post_redirect_id session key' do
         expect(session[:change_password_post_redirect_id]).
           to eq(@post_redirect.id)
      end

      it 'does not log the user in' do
        expect(session[:user_id]).to eq(nil)
      end

      it 'logs out a user who does not own the post redirect' do
        logged_in_user = FactoryGirl.create(:user)
        @user = FactoryGirl.create(:user, :email_confirmed => false)
        @post_redirect =
          PostRedirect.create(:uri => edit_password_change_path,
                              :user => @user,
                              :circumstance => 'change_password')

        session[:user_id] = logged_in_user.id
        get :confirm, :email_token => @post_redirect.email_token

        expect(session[:user_id]).to be_nil
      end

      it 'does not log out a user if they own the post redirect' do
        @user = FactoryGirl.create(:user, :email_confirmed => false)
        @post_redirect =
          PostRedirect.create(:uri => edit_password_change_path,
                              :user => @user,
                              :circumstance => 'change_password')

        session[:user_id] = @user.id
        get :confirm, :email_token => @post_redirect.email_token

        expect(session[:user_id]).to eq(@user.id)
        expect(assigns[:user]).to eq(@user)
      end

      it 'does not confirm an unconfirmed user' do
        @user = FactoryGirl.create(:user, :email_confirmed => false)
        @post_redirect =
          PostRedirect.create(:uri => edit_password_change_path,
                              :user => @user,
                              :circumstance => 'change_password')

        get :confirm, :email_token => @post_redirect.email_token

        expect(@user.reload.email_confirmed).to eq(false)
      end

      it 'sets the user_circumstance to change_password' do
        expect(session[:user_circumstance]).to eq('change_password')
      end

      it 'redirects to the post redirect uri' do
        expect(response).
          to redirect_to('/profile/change_password?post_redirect=1')
      end

    end

    context 'if the currently logged in user is an admin' do

      before :each do
        @admin = FactoryGirl.create(:admin_user)
        @user = FactoryGirl.create(:user, :email_confirmed => false)
        @post_redirect = PostRedirect.create(:uri => '/', :user => @user)

        session[:user_id] = @admin.id
        get :confirm, :email_token => @post_redirect.email_token
      end

      it 'does not confirm the post redirect user' do
        expect(@user.reload.email_confirmed).to eq(false)
      end

      it 'stays logged in as the admin user' do
        expect(session[:user_id]).to eq(@admin.id)
      end

      it 'sets the user_circumstance to normal' do
        expect(session[:user_circumstance]).to eq('normal')
      end

      it 'redirects to the post redirect uri' do
        expect(response).to redirect_to('/?post_redirect=1')
      end

    end

    context 'if the currently logged in user is not an admin and owns the post redirect' do

      before :each do
        @user = FactoryGirl.create(:user, :email_confirmed => false)
        @post_redirect = PostRedirect.create(:uri => '/', :user => @user)

        session[:user_id] = @user.id
        get :confirm, :email_token => @post_redirect.email_token
      end

      it 'confirms the post redirect user' do
        expect(@user.reload.email_confirmed).to eq(true)
      end

      it 'stays logged in as the user' do
        expect(session[:user_id]).to eq(@user.id)
      end

      it 'sets the user_circumstance to normal' do
        expect(session[:user_circumstance]).to eq('normal')
      end

      it 'redirects to the post redirect uri' do
        expect(response).to redirect_to('/?post_redirect=1')
      end

    end

    context 'if the currently logged in user is not an admin and does not own the post redirect' do

      before :each do
        @current_user = FactoryGirl.create(:user)
        @user = FactoryGirl.create(:user, :email_confirmed => false)
        @post_redirect = PostRedirect.create(:uri => '/', :user => @user)

        session[:user_id] = @current_user.id
        get :confirm, :email_token => @post_redirect.email_token
      end

      it 'confirms the post redirect user' do
        expect(@user.reload.email_confirmed).to eq(true)
      end

      # FIXME: There's no reason this should be allowed
      it 'gets logged in as the post redirect user' do
        expect(session[:user_id]).to eq(@user.id)
      end

      it 'sets the user_circumstance to normal' do
        expect(session[:user_circumstance]).to eq('normal')
      end

      it 'redirects to the post redirect uri' do
        expect(response).to redirect_to('/?post_redirect=1')
      end

    end

    context 'if there is no logged in user' do

      before :each do
        @user = FactoryGirl.create(:user, :email_confirmed => false)
        @post_redirect = PostRedirect.create(:uri => '/', :user => @user)

        get :confirm, :email_token => @post_redirect.email_token
      end

      it 'confirms the post redirect user' do
        expect(@user.reload.email_confirmed).to eq(true)
      end

      it 'gets logged in as the post redirect user' do
        expect(session[:user_id]).to eq(@user.id)
      end

      it 'sets the user_circumstance to normal' do
        expect(session[:user_circumstance]).to eq('normal')
      end

      it 'redirects to the post redirect uri' do
        expect(response).to redirect_to('/?post_redirect=1')
      end

    end

  end

end

describe UserController, "when signing in" do
  render_views

  before do
    # Don't call out to external url during tests
    allow(controller).to receive(:country_from_ip).and_return('gb')
  end

  def get_last_postredirect
    post_redirects = PostRedirect.find_by_sql("select * from post_redirects order by id desc limit 1")
    expect(post_redirects.size).to eq(1)
    post_redirects[0]
  end

  it "should show sign in / sign up page" do
    get :signin
    expect(response.body).to have_css("input#signin_token", :visible => :hidden)
  end

  it "should create post redirect to / when you just go to /signin" do
    get :signin
    post_redirect = get_last_postredirect
    expect(post_redirect.uri).to eq("/")
  end

  it "should create post redirect to /list when you click signin on /list" do
    get :signin, :r => "/list"
    post_redirect = get_last_postredirect
    expect(post_redirect.uri).to eq("/list")
  end

  it "should show you the sign in page again if you get the password wrong" do
    get :signin, :r => "/list"
    expect(response).to render_template('sign')
    post_redirect = get_last_postredirect
    post :signin, { :user_signin => { :email => 'bob@localhost', :password => 'NOTRIGHTPASSWORD' },
                    :token => post_redirect.token
                    }
    expect(response).to render_template('sign')
  end

  it "should show you the sign in page again if you get the email wrong" do
    get :signin, :r => "/list"
    expect(response).to render_template('sign')
    post_redirect = get_last_postredirect
    post :signin, :user_signin => { :email => 'unknown@localhost',
                                    :password => 'NOTRIGHTPASSWORD' },
                  :token => post_redirect.token
    expect(response).to render_template('sign')
  end

  it "should log in when you give right email/password, and redirect to where you were" do
    get :signin, :r => "/list"
    expect(response).to render_template('sign')
    post_redirect = get_last_postredirect
    post :signin, { :user_signin => { :email => 'bob@localhost', :password => 'jonespassword' },
                    :token => post_redirect.token
                    }
    expect(session[:user_id]).to eq(users(:bob_smith_user).id)
    # response doesn't contain /en/ but redirect_to does...
    expect(response).to redirect_to(:controller => 'request', :action => 'list', :post_redirect => 1)
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "should not log you in if you use an invalid PostRedirect token, and shouldn't give 500 error either" do
    post_redirect = "something invalid"
    expect {
      post :signin, { :user_signin => { :email => 'bob@localhost', :password => 'jonespassword' },
                      :token => post_redirect
                      }
    }.not_to raise_error
    post :signin, { :user_signin => { :email => 'bob@localhost', :password => 'jonespassword' },
                    :token => post_redirect }
    expect(response).to render_template('sign')
    expect(assigns[:post_redirect]).to eq(nil)
  end

  it "sets a the cookie expiry to nil on next page load" do
    load_raw_emails_data
    get_fixtures_xapian_index
    post :signin, { :user_signin => { :email => 'bob@localhost',
                                      :password => 'jonespassword' } }
    get :show, :url_name => users(:bob_smith_user).url_name
    expect(request.env['rack.session.options'][:expire_after]).to be_nil
  end

  context "checking 'remember_me'" do
    let(:user) do
      FactoryGirl.create(:user,
                         :password => 'password',
                         :email_confirmed => true)
    end

    def do_signin(email, password)
      post :signin, { :user_signin => { :email => email,
                                        :password => password },
                      :remember_me => "1" }
    end

    before do
      # fake an expired previous session which has not been reset
      # (i.e. it timed out rather than the user signing out manually)
      session[:ttl] = Time.zone.now - 2.months
    end

    it "logs the user in" do
      do_signin(user.email, 'password')
      expect(session[:user_id]).to eq(user.id)
    end

    it "sets session[:remember_me] to true" do
      do_signin(user.email, 'password')
      expect(session[:remember_me]).to eq(true)
    end

    it "clears the session[:ttl] value" do
      do_signin(user.email, 'password')
      expect(session[:ttl]).to be_nil
    end

    it "sets a long lived cookie on next page load" do
      do_signin(user.email, 'password')
      get :show, :url_name => user.url_name
      expect(request.env['rack.session.options'][:expire_after]).to eq(1.month)
    end

  end

  context 'if the user is already signed in' do
    let(:user){ FactoryGirl.create(:user) }

    before do
      ActionController::Base.allow_forgery_protection = true
    end

    after do
      ActionController::Base.allow_forgery_protection = false
    end

    it "signs them in if the credentials are valid" do
      post :signin,
           { :user_signin => { :email => user.email,
                               :password => 'jonespassword' } },
           { :user_id => user.id }
      expect(session[:user_id]).to eq(user.id)
    end

    it 'signs them out if the credentials are not valid' do
      post :signin,
           { :user_signin => { :email => user.email,
                               :password => 'wrongpassword' } },
           { :user_id => user.id }
      expect(session[:user_id]).to be_nil
    end

  end

  it "should ask you to confirm your email if it isn't confirmed, after log in" do
    get :signin, :r => "/list"
    expect(response).to render_template('sign')
    post_redirect = get_last_postredirect
    post :signin, { :user_signin => { :email => 'unconfirmed@localhost', :password => 'jonespassword' },
                    :token => post_redirect.token
                    }
    expect(response).to render_template('confirm')
    expect(ActionMailer::Base.deliveries).not_to be_empty
  end

  it 'does not redirect you to another domain' do
    get :signin, :r => "http://bad.place.com/list"
    post_redirect = get_last_postredirect
    post :signin, { :user_signin => { :email => 'unconfirmed@localhost',
                                      :password => 'jonespassword' },
                    :token => post_redirect.token
                  }
    get :confirm, :email_token => post_redirect.email_token
    expect(response).to redirect_to('/list?post_redirect=1')
  end

  it "should confirm your email, log you in and redirect you to where you were after you click an email link" do
    get :signin, :r => "/list"
    post_redirect = get_last_postredirect

    post :signin, { :user_signin => { :email => 'unconfirmed@localhost', :password => 'jonespassword' },
                    :token => post_redirect.token
                    }
    expect(ActionMailer::Base.deliveries).not_to be_empty

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(1)
    mail = deliveries[0]
    mail.body.to_s =~ /(http:\/\/.*(\/c\/(.*)))/
    mail_url = $1
    mail_path = $2
    mail_token = $3

    # check is right confirmation URL
    expect(mail_token).to eq(post_redirect.email_token)
    expect(Rails.application.routes.recognize_path(mail_path)).to eq({ :controller => 'user', :action => 'confirm', :email_token => mail_token })

    # check confirmation URL works
    expect(session[:user_id]).to be_nil
    get :confirm, :email_token => post_redirect.email_token
    expect(session[:user_id]).to eq(users(:unconfirmed_user).id)
    expect(response).to redirect_to(:controller => 'request', :action => 'list', :post_redirect => 1)
  end

  it "should keep you logged in if you click a confirmation link and are already logged in as an admin" do
    get :signin, :r => "/list"
    post_redirect = get_last_postredirect

    post :signin, { :user_signin => { :email => 'unconfirmed@localhost', :password => 'jonespassword' },
                    :token => post_redirect.token
                    }
    expect(ActionMailer::Base.deliveries).not_to be_empty

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(1)
    mail = deliveries[0]
    mail.body.to_s =~ /(http:\/\/.*(\/c\/(.*)))/
    mail_url = $1
    mail_path = $2
    mail_token = $3

    # check is right confirmation URL
    expect(mail_token).to eq(post_redirect.email_token)
    expect(Rails.application.routes.recognize_path(mail_path)).to eq({ :controller => 'user', :action => 'confirm', :email_token => mail_token })

    # Log in as an admin
    session[:user_id] = users(:admin_user).id

    # Get the confirmation URL, and check we’re still Joe
    get :confirm, :email_token => post_redirect.email_token
    expect(session[:user_id]).to eq(users(:admin_user).id)

    # And the redirect should still work, of course
    expect(response).to redirect_to(:controller => 'request', :action => 'list', :post_redirect => 1)

  end

end

describe UserController, "when signing up" do
  render_views

  before do
    # Don't call out to external url during tests
    allow(controller).to receive(:country_from_ip).and_return('gb')
  end

  it "should be an error if you type the password differently each time" do
    post :signup, { :user_signup => { :email => 'new@localhost', :name => 'New Person',
                                      :password => 'sillypassword', :password_confirmation => 'sillypasswordtwo' }
                    }
    expect(assigns[:user_signup].errors[:password_confirmation]).
      to eq(['Please enter the same password twice'])
  end

  it "should be an error to sign up with a misformatted email" do
    post :signup, { :user_signup => { :email => 'malformed-email', :name => 'Mr Malformed',
                                      :password => 'sillypassword', :password_confirmation => 'sillypassword' }
                    }
    expect(assigns[:user_signup].errors[:email]).to eq(['Please enter a valid email address'])
  end

  it "should not show the 'already in use' error when trying to sign up with a duplicate email" do
    existing_user = FactoryGirl.create(:user, :email => 'in-use@localhost')

    post :signup, { :user_signup => { :email => 'in-use@localhost', :name => 'Mr Suspected-Hacker',
                                      :password => 'sillypassword', :password_confirmation => 'mistyped' }
                    }
    expect(assigns[:user_signup].errors[:password_confirmation]).
      to eq(['Please enter the same password twice'])
    expect(assigns[:user_signup].errors[:email]).to be_empty
  end

  it "should send confirmation mail if you fill in the form right" do
    post :signup, { :user_signup => { :email => 'new@localhost', :name => 'New Person',
                                      :password => 'sillypassword', :password_confirmation => 'sillypassword' }
                    }
    expect(response).to render_template('confirm')

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(1)
    expect(deliveries[0].body).to include("not reveal your email")
  end

  it "should send confirmation mail in other languages or different locales" do
    session[:locale] = "es"
    post :signup, {:user_signup => { :email => 'new@localhost', :name => 'New Person',
                                     :password => 'sillypassword', :password_confirmation => 'sillypassword',
                                     }
                   }
    expect(response).to render_template('confirm')

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(1)
    expect(deliveries[0].body).to include("No revelaremos")
  end

  context "filling in the form with an existing registered email" do
    it "should send special 'already signed up' mail" do
      post :signup, { :user_signup => { :email => 'silly@localhost', :name => 'New Person',
                                        :password => 'sillypassword', :password_confirmation => 'sillypassword' }
                    }
      expect(response).to render_template('confirm')

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to  eq(1)

      # This text may span a line break, depending on the length of the SITE_NAME
      expect(deliveries[0].body).to match(/when\s+you\s+already\s+have\s+an/)
    end

    it "cope with trailing spaces in the email address" do
      post :signup, { :user_signup => { :email => 'silly@localhost ', :name => 'New Person',
                                        :password => 'sillypassword', :password_confirmation => 'sillypassword' }
                    }
      expect(response).to render_template('confirm')

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to  eq(1)

      # This text may span a line break, depending on the length of the SITE_NAME
      expect(deliveries[0].body).to match(/when\s+you\s+already\s+have\s+an/)
    end

    it "should create a new PostRedirect if the old one has expired" do
      allow(PostRedirect).to receive(:find_by_token).and_return(nil)
      post :signup, { :user_signup => { :email => 'silly@localhost', :name => 'New Person',
                                        :password => 'sillypassword', :password_confirmation => 'sillypassword' }
                    }
      expect(response).to render_template('confirm')
    end
  end

  it 'accepts only whitelisted parameters' do
    expect {
      post :signup, { :user_signup =>
                      { :email => 'silly@localhost',
                        :name => 'New Person',
                        :password => 'sillypassword',
                        :password_confirmation => 'sillypassword',
                        :role_ids => Role.admin_role.id } }
    }.to raise_error(ActionController::UnpermittedParameters)
  end

  context 'when the user is already signed in' do
    let(:user){ FactoryGirl.create(:user) }

    before do
      ActionController::Base.allow_forgery_protection = true
    end

    after do
      ActionController::Base.allow_forgery_protection = false
    end

    it "shows the confirmation page for valid credentials" do
      post :signup,
           { :user_signup => {
             :email => user.email,
             :name => user.name,
             :password => 'jonespassword',
             :password_confirmation => 'jonespassword' }
           },
           { :user_id => user.id }
      expect(response).to render_template('confirm')
    end

  end

  context 'when the IP is rate limited' do

    before(:each) do
      limiter = double
      allow(limiter).to receive(:record)
      allow(limiter).to receive(:limit?).and_return(true)
      allow(controller).to receive(:ip_rate_limiter).and_return(limiter)
    end

    context 'when block_rate_limited_ips? is true' do

      before(:each) do
        allow(@controller).to receive(:block_rate_limited_ips?).and_return(true)
      end

      it 'sends an exception notification' do
        post :signup,
             :user_signup => { :email => 'rate-limited@localhost',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to match(/Rate limited signup from/)
      end

      it 'blocks the signup' do
        post :signup,
             :user_signup => { :email => 'rate-limited@localhost',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(User.where(:email => 'rate-limited@localhost').count).to eq(0)
      end

      it 're-renders the form' do
        post :signup,
             :user_signup => { :email => 'rate-limited@localhost',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(response).to render_template('sign')
      end

      it 'sets a flash error' do
        post :signup,
             :user_signup => { :email => 'rate-limited@localhost',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(flash[:error]).to match(/unable to sign up new users/)
      end

    end

    context 'when block_rate_limited_ips? is false' do

      before(:each) do
        allow(@controller).
          to receive(:block_rate_limited_ips?).and_return(false)
      end

      it 'sends an exception notification' do
        post :signup,
             :user_signup => { :email => 'rate-limited@localhost',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to match(/Rate limited signup from/)
      end

      it 'allows the signup' do
        post :signup,
             :user_signup => { :email => 'rate-limited@localhost',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(User.where(:email => 'rate-limited@localhost').count).to eq(1)
      end

    end

  end

  context 'using a known spam domain' do

    before do
      spam_scorer = double
      allow(spam_scorer).
        to receive(:email_from_spam_domain?).and_return(true)
      allow(UserSpamScorer).to receive(:new).and_return(spam_scorer)
    end

    context 'when block_spam_email_domains? is true' do

      before do
        allow(@controller).
          to receive(:block_spam_email_domains?).and_return(true)
      end

      it 'logs the signup attempt' do
        msg = "Attempted signup from spam domain email: spammer@example.com"
        expect(Rails.logger).to receive(:info).with(msg)

        post :signup,
             :user_signup => { :email => 'spammer@example.com',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
      end

      it 'blocks the signup' do
        post :signup,
             :user_signup => { :email => 'spammer@example.com',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(User.where(:email => 'spammer@example.com').count).to eq(0)
      end

      it 're-renders the form' do
        post :signup,
             :user_signup => { :email => 'spammer@example.com',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(response).to render_template('sign')
      end

      it 'sets a flash error' do
        post :signup,
             :user_signup => { :email => 'spammer@example.com',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(flash[:error]).to match(/unable to sign up new users/)
      end

    end

    context 'when block_spam_email_domains? is false' do

      before do
        allow(@controller).
          to receive(:block_spam_email_domains?).and_return(false)
      end

      it 'sends an exception notification' do
        post :signup,
             :user_signup => { :email => 'spammer@example.com',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).
          to match(/signup from spam domain email: spammer@example\.com/)
      end

      it 'allows the signup' do
        post :signup,
             :user_signup => { :email => 'spammer@example.com',
                               :name => 'New Person',
                               :password => 'sillypassword',
                               :password_confirmation => 'sillypassword' }
        expect(User.where(:email => 'spammer@example.com').count).to eq(1)
      end

    end

  end

  # TODO: need to do bob@localhost signup and check that sends different email
end

describe UserController, "when signing out" do
  render_views

  it "should log you out and redirect to the home page" do
    session[:user_id] = users(:bob_smith_user).id
    get :signout
    expect(session[:user_id]).to be_nil
    expect(response).to redirect_to(:controller => 'general', :action => 'frontpage')
  end

  it "should log you out and redirect you to where you were" do
    session[:user_id] = users(:bob_smith_user).id
    get :signout, :r => '/list'
    expect(session[:user_id]).to be_nil
    expect(response).to redirect_to(:controller => 'request', :action => 'list')
  end

  it "clears the session ttl" do
    session[:user_id] = users(:bob_smith_user).id
    session[:ttl] = Time.zone.now
    get :signout
    expect(session[:ttl]).to be_nil
  end

end

describe UserController, "when sending another user a message" do
  render_views

  it "should redirect to signin page if you go to the contact form and aren't signed in" do
    get :contact, :id => users(:silly_name_user)
    expect(response).to redirect_to(:controller => 'user',
                                    :action => 'signin',
                                    :token => get_last_post_redirect.token)
  end

  it "should show contact form if you are signed in" do
    session[:user_id] = users(:bob_smith_user).id
    get :contact, :id => users(:silly_name_user)
    expect(response).to render_template('contact')
  end

  it "should give error if you don't fill in the subject" do
    session[:user_id] = users(:bob_smith_user).id
    post :contact, { :id => users(:silly_name_user), :contact => { :subject => "", :message => "Gah" }, :submitted_contact_form => 1 }
    expect(response).to render_template('contact')
  end

  it "should send the message" do
    session[:user_id] = users(:bob_smith_user).id
    post :contact, { :id => users(:silly_name_user), :contact => { :subject => "Dearest you", :message => "Just a test!" }, :submitted_contact_form => 1 }
    expect(response).to redirect_to(:controller => 'user', :action => 'show', :url_name => users(:silly_name_user).url_name)

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(1)
    mail = deliveries[0]
    expect(mail.body).to include("Bob Smith has used #{AlaveteliConfiguration::site_name} to send you the message below")
    expect(mail.body).to include("Just a test!")
    #mail.to_addrs.first.to_s.should == users(:silly_name_user).name_and_email # TODO: fix some nastiness with quoting name_and_email
    expect(mail.header['Reply-To'].to_s).to match(users(:bob_smith_user).email)
  end

end

describe UserController, "when changing email address" do
  render_views

  it "should require login" do
    get :signchangeemail
    expect(response).to redirect_to(:controller => 'user',
                                    :action => 'signin',
                                    :token => get_last_post_redirect.token)
  end

  it "should show form for changing email if logged in" do
    @user = users(:bob_smith_user)
    session[:user_id] = @user.id

    get :signchangeemail

    expect(response).to render_template('signchangeemail')
  end

  it "should be an error if the password is wrong, everything else right" do
    @user = users(:bob_smith_user)
    session[:user_id] = @user.id

    post :signchangeemail, { :signchangeemail => { :old_email => 'bob@localhost',
                                                   :password => 'donotknowpassword', :new_email => 'newbob@localhost' },
                             :submitted_signchangeemail_do => 1
                             }

    @user.reload
    expect(@user.email).to eq('bob@localhost')
    expect(response).to render_template('signchangeemail')
    expect(assigns[:signchangeemail].errors[:password]).not_to be_nil

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(0)
  end

  it "should be an error if old email is wrong, everything else right" do
    @user = users(:bob_smith_user)
    session[:user_id] = @user.id

    post :signchangeemail, { :signchangeemail => { :old_email => 'bob@moo',
                                                   :password => 'jonespassword', :new_email => 'newbob@localhost' },
                             :submitted_signchangeemail_do => 1
                             }

    @user.reload
    expect(@user.email).to eq('bob@localhost')
    expect(response).to render_template('signchangeemail')
    expect(assigns[:signchangeemail].errors[:old_email]).not_to be_nil

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(0)
  end

  it "should work even if the old email had a case difference" do
    @user = users(:bob_smith_user)
    session[:user_id] = @user.id

    post :signchangeemail, { :signchangeemail => { :old_email => 'BOB@localhost',
                                                   :password => 'jonespassword', :new_email => 'newbob@localhost' },
                             :submitted_signchangeemail_do => 1
                             }

    expect(response).to render_template('signchangeemail_confirm')
  end

  it "should send confirmation email if you get all the details right" do
    @user = users(:bob_smith_user)
    session[:user_id] = @user.id

    post :signchangeemail, { :signchangeemail => { :old_email => 'bob@localhost',
                                                   :password => 'jonespassword', :new_email => 'newbob@localhost' },
                             :submitted_signchangeemail_do => 1
                             }

    @user.reload
    expect(@user.email).to eq('bob@localhost')
    expect(@user.email_confirmed).to eq(true)

    expect(response).to render_template('signchangeemail_confirm')

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(1)
    mail = deliveries[0]
    expect(mail.body).to include("confirm that you want to change")
    expect(mail.to).to eq([ 'newbob@localhost' ])

    mail.body.to_s =~ /(http:\/\/.*(\/c\/(.*)))/
    mail_url = $1
    mail_path = $2
    mail_token = $3

    # Check confirmation URL works
    session[:user_id] = nil
    expect(session[:user_circumstance]).to eq(nil)
    get :confirm, :email_token => mail_token
    expect(session[:user_id]).to eq(users(:bob_smith_user).id)
    expect(session[:user_circumstance]).to eq('change_email')
    expect(response).to redirect_to(:controller => 'user', :action => 'signchangeemail', :post_redirect => 1)

    # Would be nice to do a follow_redirect! here, but rspec-rails doesn't
    # have one. Instead do an equivalent manually.
    post_redirect = PostRedirect.find_by_email_token(mail_token)
    expect(post_redirect.circumstance).to eq('change_email')
    expect(post_redirect.user).to eq(users(:bob_smith_user))
    expect(post_redirect.post_params).to eq({"submitted_signchangeemail_do"=>"1",
                                         "action"=>"signchangeemail",
                                         "signchangeemail"=>{
                                           "old_email"=>"bob@localhost",
                                         "new_email"=>"newbob@localhost"},
                                         "controller"=>"user"})
    post :signchangeemail, post_redirect.post_params

    expect(response).to redirect_to(:controller => 'user', :action => 'show', :url_name => 'bob_smith')
    expect(flash[:notice]).to match(/You have now changed your email address/)
    @user.reload
    expect(@user.email).to eq('newbob@localhost')
    expect(@user.email_confirmed).to eq(true)
  end

  it "should send special 'already signed up' mail if you try to change your email to one already used" do
    @user = users(:bob_smith_user)
    session[:user_id] = @user.id

    post :signchangeemail, { :signchangeemail => { :old_email => 'bob@localhost',
                                                   :password => 'jonespassword', :new_email => 'silly@localhost' },
                             :submitted_signchangeemail_do => 1
                             }

    @user.reload
    expect(@user.email).to eq('bob@localhost')
    expect(@user.email_confirmed).to eq(true)

    expect(response).to render_template('signchangeemail_confirm')

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(1)
    mail = deliveries[0]

    expect(mail.body).to include("perhaps you, just tried to change their")
    expect(mail.to).to eq([ 'silly@localhost' ])
  end
end

describe UserController, "when using profile photos" do
  render_views

  before do
    @user = users(:bob_smith_user)

    @uploadedfile = fixture_file_upload("/files/parrot.png")
    @uploadedfile_2 = fixture_file_upload("/files/parrot.jpg")
  end

  it "should not let you change profile photo if you're not logged in as the user" do
    post :set_profile_photo, { :id => @user.id, :file => @uploadedfile, :submitted_draft_profile_photo => 1, :automatically_crop => 1 }
  end

  it "should return a 404 not a 500 when a profile photo has not been set" do
    expect(@user.profile_photo).to be_nil
    expect {
      get :get_profile_photo, {:url_name => @user.url_name }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "should let you change profile photo if you're logged in as the user" do
    expect(@user.profile_photo).to be_nil
    session[:user_id] = @user.id

    post :set_profile_photo, { :id => @user.id, :file => @uploadedfile, :submitted_draft_profile_photo => 1, :automatically_crop => 1 }

    expect(response).to redirect_to(:controller => 'user', :action => 'show', :url_name => "bob_smith")
    expect(flash[:notice]).to match(/Thank you for updating your profile photo/)

    @user.reload
    expect(@user.profile_photo).not_to be_nil
  end

  context 'there is no profile text' do
    let(:user) { FactoryGirl.create(:user, :about_me => '') }

    it 'prompts you to add profile text when adding a photo' do
      session[:user_id] = user.id

      profile_photo = ProfilePhoto.
                        create(:data => load_file_fixture("parrot.png"),
                               :user => user)

      post :set_profile_photo, { :id => user.id,
                                 :file => @uploadedfile,
                                 :submitted_crop_profile_photo => 1,
                                 :draft_profile_photo_id => profile_photo.id }

      expect(flash[:notice][:partial]).
        to eq("user/update_profile_photo.html.erb")
    end

  end

  it "should let you change profile photo twice" do
    expect(@user.profile_photo).to be_nil
    session[:user_id] = @user.id

    post :set_profile_photo, { :id => @user.id, :file => @uploadedfile, :submitted_draft_profile_photo => 1, :automatically_crop => 1 }
    expect(response).to redirect_to(:controller => 'user', :action => 'show', :url_name => "bob_smith")
    expect(flash[:notice]).to match(/Thank you for updating your profile photo/)

    post :set_profile_photo, { :id => @user.id, :file => @uploadedfile_2, :submitted_draft_profile_photo => 1, :automatically_crop => 1 }
    expect(response).to redirect_to(:controller => 'user', :action => 'show', :url_name => "bob_smith")
    expect(flash[:notice]).to match(/Thank you for updating your profile photo/)

    @user.reload
    expect(@user.profile_photo).not_to be_nil
  end

  # TODO: todo check the two stage javascript cropping (above only tests one stage non-javascript one)
end

describe UserController, "when showing JSON version for API" do

  it "should be successful" do
    get :show, :url_name => "bob_smith", :format => "json"

    u = JSON.parse(response.body)
    expect(u.class.to_s).to eq('Hash')

    expect(u['url_name']).to eq('bob_smith')
    expect(u['name']).to eq('Bob Smith')
  end

end

describe UserController, "when viewing the wall" do
  render_views

  before(:each) do
    load_raw_emails_data
    get_fixtures_xapian_index
  end

  it "should show users stuff on their wall, most recent first" do
    user = users(:silly_name_user)
    ire = info_request_events(:useless_incoming_message_event)
    ire.created_at = DateTime.new(2001,1,1)
    session[:user_id] = user.id
    get :wall, :url_name => user.url_name
    expect(assigns[:feed_results][0]).not_to eq(ire)

    ire.created_at = Time.zone.now
    ire.save!
    get :wall, :url_name => user.url_name
    expect(assigns[:feed_results][0]).to eq(ire)
  end

  it "should show other users' activities on their walls" do
    user = users(:silly_name_user)
    ire = info_request_events(:useless_incoming_message_event)
    get :wall, :url_name => user.url_name
    expect(assigns[:feed_results][0]).not_to eq(ire)
  end

  it "should allow users to turn their own email alerts on and off" do
    user = users(:silly_name_user)
    session[:user_id] = user.id
    expect(user.receive_email_alerts).to eq(true)
    get :set_receive_email_alerts, :receive_email_alerts => 'false', :came_from => "/"
    user.reload
    expect(user.receive_email_alerts).not_to eq(true)
  end

  it 'should not show duplicate feed results' do
    user = users(:silly_name_user)
    session[:user_id] = user.id
    get :wall, :url_name => user.url_name
    expect(assigns[:feed_results].uniq).to eq(assigns[:feed_results])
  end

end
