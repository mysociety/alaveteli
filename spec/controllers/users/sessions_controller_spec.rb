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

    it "should show you the sign in page again if you get the password wrong" do
      post_redirect = FactoryGirl.create(:post_redirect, uri: '/list')
      post :create, { :user_signin => { :email => 'bob@localhost', :password => 'NOTRIGHTPASSWORD' },
                      :token => post_redirect.token
                      }
      expect(response).to render_template('user/sign')
    end

    it "should show you the sign in page again if you get the email wrong" do
      post_redirect = FactoryGirl.create(:post_redirect, uri: '/list')
      post :create, :user_signin => { :email => 'unknown@localhost',
                                      :password => 'NOTRIGHTPASSWORD' },
                    :token => post_redirect.token
      expect(response).to render_template('user/sign')
    end

    it "should log in when you give right email/password, and redirect to where you were" do
      post_redirect = FactoryGirl.create(:post_redirect, uri: '/list')

      post :create, { :user_signin => { :email => 'bob@localhost', :password => 'jonespassword' },
                      :token => post_redirect.token
                      }
      expect(session[:user_id]).to eq(users(:bob_smith_user).id)
      # response doesn't contain /en/ but redirect_to does...
      expect(response).to redirect_to(request_list_path(post_redirect: 1))
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "should not log you in if you use an invalid PostRedirect token, and shouldn't give 500 error either" do
      post_redirect = "something invalid"
      expect {
        post :create, { :user_signin => { :email => 'bob@localhost', :password => 'jonespassword' },
                        :token => post_redirect
                        }
      }.not_to raise_error
      post :create, { :user_signin => { :email => 'bob@localhost', :password => 'jonespassword' },
                      :token => post_redirect }
      expect(response).to render_template('user/sign')
      expect(assigns[:post_redirect]).to eq(nil)
    end

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

    context 'if the user is already signed in' do
      let(:user){ FactoryGirl.create(:user) }

      before do
        ActionController::Base.allow_forgery_protection = true
      end

      after do
        ActionController::Base.allow_forgery_protection = false
      end

      it "signs them in if the credentials are valid" do
        post :create,
             { :user_signin => { :email => user.email,
                                 :password => 'jonespassword' } },
             { :user_id => user.id }
        expect(session[:user_id]).to eq(user.id)
      end

      it 'signs them out if the credentials are not valid' do
        post :create,
             { :user_signin => { :email => user.email,
                                 :password => 'wrongpassword' } },
             { :user_id => user.id }
        expect(session[:user_id]).to be_nil
      end

    end

    it "should ask you to confirm your email if it isn't confirmed, after log in" do
      post_redirect = FactoryGirl.create(:post_redirect, uri: '/list')

      post :create, { :user_signin => { :email => 'unconfirmed@localhost', :password => 'jonespassword' },
                      :token => post_redirect.token
                      }
      expect(response).to render_template('user/confirm')
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    # TODO: Extract to integration spec
    pending 'does not redirect you to another domain' do
      post_redirect =
        FactoryGirl.create(:post_redirect, uri: 'http://bad.place.com/list')

      post :create, { :user_signin => { :email => 'unconfirmed@localhost',
                                        :password => 'jonespassword' },
                      :token => post_redirect.token
                    }
      get :confirm, :email_token => post_redirect.email_token
      expect(response).to redirect_to('/list?post_redirect=1')
    end

    # TODO: Extract to integration spec
    pending "should confirm your email, log you in and redirect you to where you were after you click an email link" do
      post_redirect = FactoryGirl.create(:post_redirect, uri: '/list')

      post :create, { :user_signin => { :email => 'unconfirmed@localhost', :password => 'jonespassword' },
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

    # TODO: Extract to integration spec
    pending "should keep you logged in if you click a confirmation link and are already logged in as an admin" do
      post_redirect = FactoryGirl.create(:post_redirect, uri: '/list')

      post :create, { :user_signin => { :email => 'unconfirmed@localhost', :password => 'jonespassword' },
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
