require 'spec_helper'

RSpec.describe Users::SessionsController do
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
      get :new, params: { r: "/list" }
      post_redirect = get_last_post_redirect
      expect(post_redirect.uri).to eq("/list")
    end

    context 'if the user is already signed in' do
      let(:user) { FactoryBot.create(:user) }

      before do
        ActionController::Base.allow_forgery_protection = true
        sign_in user
      end

      after do
        ActionController::Base.allow_forgery_protection = false
      end

      it 'redirects to the homepage' do
        get :new
        expect(response).to redirect_to(frontpage_path)
      end

      it 'redirects to the redirect parameter' do
        get :new, params: { r: '/select_authority' }
        expect(response).to redirect_to(select_authority_path)
      end
    end
  end

  describe 'POST create' do
    let(:user) { FactoryBot.create(:user) }

    it "should show you the sign in page again if you get the password wrong" do
      post_redirect = FactoryBot.create(:post_redirect, uri: '/list')
      post :create, params: {
                      user_signin: {
                        email: 'bob@localhost',
                        password: 'NOTRIGHTPASSWORD'
                      },
                      token: post_redirect.token
                    }
      expect(response).to render_template('user/sign')
    end

    it "should show you the sign in page again if you get the email wrong" do
      post_redirect = FactoryBot.create(:post_redirect, uri: '/list')
      post :create, params: {
                      user_signin: {
                        email: 'unknown@localhost',
                        password: 'NOTRIGHTPASSWORD'
                      },
                      token: post_redirect.token
                    }
      expect(response).to render_template('user/sign')
    end

    it "should log in when you give right email/password, and redirect to where you were" do
      post_redirect = FactoryBot.create(:post_redirect, uri: '/list')

      post :create, params: {
                      user_signin: {
                        email: 'bob@localhost',
                        password: 'jonespassword'
                      },
                      token: post_redirect.token
                    }
      expect(session[:user_id]).to eq(users(:bob_smith_user).id)
      # response doesn't contain /en/ but redirect_to does...
      expect(response).to redirect_to(request_list_path(post_redirect: 1))
      expect(deliveries).to be_empty
    end

    it "should not log you in if you use an invalid PostRedirect token, and shouldn't give 500 error either" do
      post_redirect = "something invalid"
      expect {
        post :create, params: {
                        user_signin: {
                          email: 'bob@localhost',
                          password: 'jonespassword'
                        },
                        token: post_redirect
                      }
      }.not_to raise_error

      post :create, params: {
                      user_signin: {
                        email: 'bob@localhost',
                        password: 'jonespassword'
                      },
                      token: post_redirect
                    }
      expect(response).to render_template('user/sign')
      expect(assigns[:post_redirect]).to eq(nil)
    end

    it "sets a the cookie expiry to nil on next page load" do
      post :create, params: {
                      user_signin: {
                        email: user.email,
                        password: 'jonespassword'
                      }
                    }
      get :new
      expect(request.env['rack.session.options'][:expire_after]).to be_nil
    end

    it "does not log you in if you use an invalid PostRedirect token" do
      post_redirect = "something invalid"
      post :create, params: {
                      user_signin: {
                        email: 'bob@localhost',
                        password: 'jonespassword'
                      },
                      token: post_redirect
                    }
      expect(response).to render_template('sign')
      expect(assigns[:post_redirect]).to eq(nil)
    end

    context 'when the user_signin param is empty' do
      # Usually automated bots that submit the form without this param
      before { post :create, params: { foo: {} } }

      it 're-renders the form' do
        expect(response).to render_template('user/sign')
      end

      it 'renders a simple error message' do
        expect(flash[:error]).to eq('Invalid form submission')
      end
    end

    context "checking 'remember_me'" do
      let(:user) do
        FactoryBot.create(:user,
                          password: 'password1234',
                          email_confirmed: true)
      end

      def do_signin(email, password)
        post :create, params: {
                        user_signin: {
                          email: email,
                          password: password
                        },
                        remember_me: "1"
                      }
      end

      before do
        # fake an expired previous session which has not been reset
        # (i.e. it timed out rather than the user signing out manually)
        session[:ttl] = Time.zone.now - 2.months
      end

      it "logs the user in" do
        do_signin(user.email, 'password1234')
        expect(session[:user_id]).to eq(user.id)
      end

      it "sets session[:remember_me] to true" do
        do_signin(user.email, 'password1234')
        expect(session[:remember_me]).to eq(true)
      end

      it "clears the session[:ttl] value" do
        do_signin(user.email, 'password1234')
        expect(session[:ttl]).to be_nil
      end

      it "sets a long lived cookie on next page load" do
        do_signin(user.email, 'password1234')
        get :new
        expect(request.env['rack.session.options'][:expire_after]).
          to eq(1.month)
      end
    end

    context 'if the user is already signed in' do
      let(:user) { FactoryBot.create(:user) }

      before do
        ActionController::Base.allow_forgery_protection = true
      end

      after do
        ActionController::Base.allow_forgery_protection = false
      end

      it "signs them in if the credentials are valid" do
        post :create, params: {
                        user_signin: {
                          email: user.email,
                          password: 'jonespassword'
                        }
                      },
                      session: { user_id: user.id }
        expect(session[:user_id]).to eq(user.id)
      end

      it 'signs them out if the credentials are not valid' do
        post :create, params: {
                        user_signin: {
                          email: user.email,
                          password: 'wrongpassword'
                        }
                      },
                      session: { user_id: user.id }
        expect(session[:user_id]).to be_nil
      end
    end

    context 'using a spammy name or email from a known spam domain' do
      let(:user) do
        FactoryBot.create(
          :user,
          email: 'spammer@example.com', name: 'Download New Person 1080p!',
          password: 'password1234', email_confirmed: true
        )
      end

      def do_signin(email, password)
        post :create, params: {
          user_signin: { email: email, password: password }
        }
      end

      before do
        spam_scorer = double
        allow(spam_scorer).to receive(:spam?).and_return(true)
        allow(UserSpamScorer).to receive(:new).and_return(spam_scorer)
      end

      context 'when spam_should_be_blocked? is true' do
        before do
          allow(@controller).
            to receive(:spam_should_be_blocked?).and_return(true)
        end

        it 'logs the signup attempt' do
          msg = "Attempted signup from suspected spammer, " \
                "email: spammer@example.com, " \
                "name: 'Download New Person 1080p!'"
          allow(Rails.logger).to receive(:info)
          expect(Rails.logger).to receive(:info).with(msg)

          do_signin(user.email, 'password1234')
        end

        it 'blocks the signup' do
          do_signin(user.email, 'password1234')
          expect(session[:user_id]).to be_nil
        end

        it 're-renders the form' do
          do_signin(user.email, 'password1234')
          expect(response).to render_template('sign')
        end
      end

      context 'when spam_should_be_blocked? is false' do
        before do
          allow(@controller).
            to receive(:spam_should_be_blocked?).and_return(false)
        end

        it 'sends an exception notification' do
          do_signin(user.email, 'password1234')
          mail = deliveries.first
          expect(mail.subject).to match(/signup from suspected spammer/)
        end

        it 'allows the signin' do
          do_signin(user.email, 'password1234')
          expect(session[:user_id]).to eq user.id
        end
      end
    end

    it "should ask you to confirm your email if it isn't confirmed, after log in" do
      post_redirect = FactoryBot.create(:post_redirect, uri: '/list')

      post :create, params: {
                      user_signin: {
                        email: 'unconfirmed@localhost',
                        password: 'jonespassword'
                      },
                      token: post_redirect.token
                    }

      expect(response).to render_template('user/confirm')
      expect(deliveries).not_to be_empty
    end

    # TODO: Extract to integration spec
    it 'does not redirect you to another domain' do
      pending('Extract to an integration spec')

      post_redirect =
        FactoryBot.create(:post_redirect, uri: 'http://bad.place.com/list')

      post :create, params: {
                      user_signin: {
                        email: 'unconfirmed@localhost',
                        password: 'jonespassword'
                      },
                      token: post_redirect.token
                    }
      get :confirm, params: { email_token: post_redirect.email_token }
      expect(response).to redirect_to('/list?post_redirect=1')
    end

    # TODO: Extract to integration spec
    it "should confirm your email, log you in and redirect you to where you were after you click an email link" do
      pending('Extract to an integration spec')

      post_redirect = FactoryBot.create(:post_redirect, uri: '/list')

      post :create, params: {
                      user_signin: {
                        email: 'unconfirmed@localhost',
                        password: 'jonespassword'
                      },
                      token: post_redirect.token
                    }
      expect(deliveries).not_to be_empty

      expect(deliveries.size).to eq(1)
      mail = deliveries.first
      mail.body.to_s =~ /(http:\/\/.*(\/c\/(.*)))/
      mail_url = $1
      mail_path = $2
      mail_token = $3

      # check is right confirmation URL
      expect(mail_token).to eq(post_redirect.email_token)
      expect(Rails.application.routes.recognize_path(mail_path)).to eq(
        {
          controller: 'user',
          action: 'confirm',
          email_token: mail_token
        }
      )

      # check confirmation URL works
      expect(session[:user_id]).to be_nil
      get :confirm, params: { email_token: post_redirect.email_token }
      expect(session[:user_id]).to eq(users(:unconfirmed_user).id)
      expect(response).to redirect_to(
        controller: 'request',
        action: 'list',
        post_redirect: 1
      )
    end

    # TODO: Extract to integration spec
    it "should keep you logged in if you click a confirmation link and are already logged in as an admin" do
      pending('Extract to an integration spec')

      post_redirect = FactoryBot.create(:post_redirect, uri: '/list')

      post :create, params: {
                      user_signin: {
                        email: 'unconfirmed@localhost',
                        password: 'jonespassword'
                      },
                      token: post_redirect.token
                    }
      expect(deliveries).not_to be_empty

      expect(deliveries.size).to eq(1)
      mail = deliveries.first
      mail.body.to_s =~ /(http:\/\/.*(\/c\/(.*)))/
      mail_url = $1
      mail_path = $2
      mail_token = $3

      # check is right confirmation URL
      expect(mail_token).to eq(post_redirect.email_token)
      expect(Rails.application.routes.recognize_path(mail_path)).to eq(
        {
          controller: 'user',
          action: 'confirm',
          email_token: mail_token
        }
      )

      # Log in as an admin
      sign_in users(:admin_user)

      # Get the confirmation URL, and check we’re still Joe
      get :confirm, params: { email_token: post_redirect.email_token }
      expect(session[:user_id]).to eq(users(:admin_user).id)

      # And the redirect should still work, of course
      expect(response).to redirect_to(
        controller: 'request',
        action: 'list',
        post_redirect: 1
      )
    end
  end

  describe 'GET destroy' do
    let(:user) { FactoryBot.create(:user) }

    it "logs you out and redirect to the home page" do
      sign_in user
      get :destroy
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(frontpage_path)
    end

    it "logs you out and redirect you to where you were" do
      sign_in user
      get :destroy, params: { r: '/list' }
      expect(session[:user_id]).to be_nil
      expect(response).
        to redirect_to(request_list_path)
    end

    it "clears the session ttl" do
      get :destroy, session: { user_id: user.id, ttl: Time.zone.now }
      expect(session[:ttl]).to be_nil
    end
  end
end
