# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Users::SessionsController do

  before do
    # Don't call out to external url during tests
    allow(controller).to receive(:country_from_ip).and_return('gb')
  end

  describe 'GET new' do

    it "should show sign in / sign up page" do
      get :new
      expect(response.body).to render_template('user/sign')
    end

    it "should create post redirect to / when you just go to /signin" do
      get :new
      post_redirect = get_last_post_redirect
      expect(post_redirect.uri).to eq("/")
    end

    it "should create post redirect to /list when you click signin on /list" do
      get :new, :r => "/list"
      post_redirect = get_last_post_redirect
      expect(post_redirect.uri).to eq("/list")
    end
  end

  describe 'POST create' do
    let(:user) { FactoryGirl.create(:user) }

    it "sets a the cookie expiry to nil on next page load" do
      post :create, { :user_signin => { :email => user.email,
                                        :password => 'jonespassword' } }
      get :new
      expect(request.env['rack.session.options'][:expire_after]).to be_nil
    end

    it "does not log you in if you use an invalid PostRedirect token" do
      post_redirect = "something invalid"
      post :create, { :user_signin => { :email => 'bob@localhost',
                                        :password => 'jonespassword' },
                      :token => post_redirect }
      expect(response).to render_template('sign')
      expect(assigns[:post_redirect]).to eq(nil)
    end

    context "checking 'remember_me'" do
      let(:user) do
        FactoryGirl.create(:user,
                           :password => 'password',
                           :email_confirmed => true)
      end

      def do_signin(email, password)
        post :create, { :user_signin => { :email => email,
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
        get :new
        expect(request.env['rack.session.options'][:expire_after]).
          to eq(1.month)
      end
    end
  end

  describe 'GET destroy' do
    let(:user) { FactoryGirl.create(:user) }

    it "logs you out and redirect to the home page" do
      get :destroy, {}, { :user_id => user.id }
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(frontpage_path)
    end

    it "logs you out and redirect you to where you were" do
      get :destroy, { :r => '/list' }, { :user_id => user.id }
      expect(session[:user_id]).to be_nil
      expect(response).
        to redirect_to(request_list_path)
    end

    it "clears the session ttl" do
      get :destroy, {}, { :user_id => user.id, :ttl => Time.zone.now }
      expect(session[:ttl]).to be_nil
    end

  end

end
