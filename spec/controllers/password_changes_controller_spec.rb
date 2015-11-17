# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PasswordChangesController do

  describe 'GET new' do

    it 'assigns the pretoken if supplied' do
      get :new, :pretoken => 'abcdef'
      expect(assigns[:pretoken]).to eq('abcdef')
    end

    it 'assigns nil to the pretoken if not supplied' do
      get :new
      expect(assigns[:pretoken]).to eq(nil)
    end

    it 'assigns nil to the pretoken if blank' do
      get :new, :pretoken => ''
      expect(assigns[:pretoken]).to eq(nil)
    end

    it 'does not pre-fill the email field without a signed in user' do
      get :new
      expect(assigns[:email_field_options]).to eq({})
    end

    it 'pre-fills the email field for a signed in user' do
      user = FactoryGirl.create(:user)
      session[:user_id] = user.id
      get :new
      expect(assigns[:email_field_options][:value]).to eq(user.email)
    end

    it 'disables the email field for a signed in user' do
      user = FactoryGirl.create(:user)
      session[:user_id] = user.id
      get :new
      expect(assigns[:email_field_options][:disabled]).to eq(true)
    end

    it 'renders the template' do
      get :new
      expect(response).to render_template(:new)
    end

  end

  describe 'POST create' do

    context 'when a user is signed in' do

      it 'ignores an email submitted in the post params' do
        user = FactoryGirl.create(:user)
        session[:user_id] = user.id
        post :create, :password_change_user => { :email => 'hacker@localhost' }
        expect(assigns[:password_change_user]).to eq(user)
      end

      it 'does not require an email to be submitted' do
        user = FactoryGirl.create(:user)
        session[:user_id] = user.id
        post :create
        expect(assigns[:password_change_user]).to eq(user)
      end
    end

    context 'when receiving an email address of an existing user' do

      it 'assigns the user' do
        user = FactoryGirl.create(:user)
        post :create, :password_change_user => { :email => user.email }
        expect(assigns[:password_change_user]).to eq(user)
      end

      it 'creates a post redirect' do
        user = FactoryGirl.create(:user)
        expected_attrs =
          { :uri => edit_password_change_url,
            :post_params => {},
            :reason_params => {
              :web => '',
              :email => _('Then you can change your password on {{site_name}}',
                          :site_name => AlaveteliConfiguration.site_name),
              :email_subject => _('Change your password on {{site_name}}',
                                  :site_name =>
                                    AlaveteliConfiguration.site_name) },
            :circumstance => 'change_password' }

        post :create, :password_change_user => { :email => user.email }

        post_redirect = PostRedirect.last

        post_redirect_attrs = { :uri => post_redirect.uri,
                                :post_params => post_redirect.post_params,
                                :reason_params => post_redirect.reason_params,
                                :circumstance => post_redirect.circumstance }

        expect(post_redirect_attrs).to eq(expected_attrs)
      end

      context 'when a pretoken is supplied' do

        it 'adds the pretoken to the post redirect uri' do
          user = FactoryGirl.create(:user)
          pretoken = PostRedirect.create(:user => user, :uri => '/')
          post :create, :password_change_user => { :email => user.email },
                        :pretoken => pretoken.token
          expected = edit_password_change_url(:pretoken => pretoken.token)
          expect(PostRedirect.last.uri).to include(expected)
        end

        it 'does not add a blank pretoken to the post redirect uri' do
          user = FactoryGirl.create(:user)
          pretoken = PostRedirect.create(:user => user, :uri => '/')
          post :create, :password_change_user => { :email => user.email },
                        :pretoken => ''
          expect(PostRedirect.last.uri).to eq(edit_password_change_url)
        end

      end

      it 'sends a confirmation email' do
        user = FactoryGirl.create(:user)

        post :create, :password_change_user => { :email => user.email }

        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq('Change your password on Alaveteli')
        ActionMailer::Base.deliveries.clear
      end

      it 'does not send a confirmation email for an unknown email' do
        post :create, :password_change_user =>
                        { :email => 'unknown-email@example.org' }
        expect(ActionMailer::Base.deliveries.size).to eq(0)
      end

      it 'renders the confirmation message' do
        user = FactoryGirl.create(:user)
        post :create, :password_change_user => { :email => user.email }
        expect(response).to render_template(:check_email)
      end

      it 'renders the confirmation message for an unknown email' do
        post :create, :password_change_user =>
                        { :email => 'unknown-email@example.org' }
        expect(response).to render_template(:check_email)
      end

      it 'warns the user of an invalid email format' do
        msg = "That doesn't look like a valid email address. Please check " \
              "you have typed it correctly."
        post :create, :password_change_user => { :email => 'invalid-email' }
        expect(flash[:error]).to eq(msg)
      end

      it 're-renders the form with an invalid email format' do
        post :create, :password_change_user => { :email => 'invalid-email' }
        expect(response).to render_template(:new)
      end

    end

  end

  describe 'GET edit' do

    it 'assigns the pretoken if supplied' do
      get :edit, :pretoken => 'abcdef'
      expect(assigns[:pretoken]).to eq('abcdef')
    end

    it 'assigns nil to the pretoken if not supplied' do
      get :edit
      expect(assigns[:pretoken]).to eq(nil)
    end

    it 'assigns nil to the pretoken if blank' do
      get :edit, :pretoken => ''
      expect(assigns[:pretoken]).to eq(nil)
    end

    context 'no user is specified' do

      it 'redirects to new for the user to enter their email' do
        get :edit
        expect(response).to redirect_to(new_password_change_path)
      end

      it 'redirects to new with a pretoken for the user to enter their email' do
        get :edit, :pretoken => 'abcdef'
        expect(response).
          to redirect_to(new_password_change_path(:pretoken => 'abcdef'))
      end
    end

    context 'a user is logged in' do

      it 'redirects to new to force an email confirmation' do
        user = FactoryGirl.create(:user)
        session[:user_id] = user
        get :edit
        expect(response).to redirect_to new_password_change_path
      end

    end

    context 'a user has been redirected from a post redirect' do

      it 'assigns the user from a post redirect' do
        user = FactoryGirl.create(:user)
        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        session[:change_password_post_redirect_id] = post_redirect.id

        get :edit

        expect(assigns[:password_change_user]).to eq(user)
      end

    end

  end

  describe 'PUT update' do
    before(:each) do
      @valid_password_params =
        { :password => 'secret',
          :password_confirmation => 'secret' }
      @invalid_password_params =
        { :password => 'secret',
          :password_confirmation => 'password' }
    end

    context 'no user is specified' do

      it 'redirects to #new when a user cannot be found' do
        put :update, :password_change_user => @valid_password_params
        expect(response).to redirect_to(new_password_change_path)
      end

    end

    context 'a user is logged in' do

      it 'redirects to new to force an email confirmation' do
        user = FactoryGirl.create(:user)
        session[:user_id] = user
        put :update, :password_change_user => @valid_password_params
        expect(response).to redirect_to new_password_change_path
      end

    end

    context 'a user has been redirected from a post redirect' do

      it 'assigns the user from a post redirect' do
        user = FactoryGirl.create(:user)
        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        session[:change_password_post_redirect_id] = post_redirect.id

        put :update, :password_change_user => @valid_password_params

        expect(assigns[:password_change_user]).to eq(user)
      end

      it 'clears the session key and value on success' do
        user = FactoryGirl.create(:user)
        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        session[:change_password_post_redirect_id] = post_redirect.id
        put :update, :password_change_user => @valid_password_params
        expect(session.key?(:change_password_post_redirect_id)).to eq(false)
      end

      it 'retains the session key and value on failure' do
        user = FactoryGirl.create(:user)
        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        session[:change_password_post_redirect_id] = post_redirect.id
        put :update, :password_change_user => @invalid_password_params
        expect(session[:change_password_post_redirect_id]).
          to eq(post_redirect.id)
      end

      it 'logs in the user on success' do
        user = FactoryGirl.create(:user)
        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        session[:change_password_post_redirect_id] = post_redirect.id
        put :update, :password_change_user => @valid_password_params
        expect(session[:user_id]).to eq(user.id)
      end

      it 'clears the user_circumstance session on success' do
        user = FactoryGirl.create(:user)
        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        session[:change_password_post_redirect_id] = post_redirect.id
        session[:user_circumstance] = 'change_password'
        put :update, :password_change_user => @valid_password_params
        expect(session[:user_circumstance]).to be_nil
      end

    end

    it 'changes the password on success' do
      user = FactoryGirl.create(:user)
      old_hash = user.hashed_password
      post_redirect =
        PostRedirect.create(:user => user, :uri => frontpage_url)
      session[:change_password_post_redirect_id] = post_redirect.id
      put :update, :password_change_user => @valid_password_params
      expect(user.reload.hashed_password).not_to eq(old_hash)
    end

    it 'retains the old password on failure' do
      user = FactoryGirl.create(:user)
      old_hash = user.hashed_password
      post_redirect =
        PostRedirect.create(:user => user, :uri => frontpage_url)
      session[:change_password_post_redirect_id] = post_redirect.id
      put :update, :password_change_user => @invalid_password_params
      expect(user.reload.hashed_password).to eq(old_hash)
    end

    it 'notifies the user the password change has been successful' do
      user = FactoryGirl.create(:user)
      post_redirect =
        PostRedirect.create(:user => user, :uri => frontpage_url)
      session[:change_password_post_redirect_id] = post_redirect.id
      put :update, :password_change_user => @valid_password_params
      expect(flash[:notice]).to eq('Your password has been changed.')
    end

    context 'when a pretoken is supplied' do

      it 'redirects to the post redirect uri' do
        user = FactoryGirl.create(:user)
        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        pretoken = PostRedirect.create(:user => user, :uri => '/')
        session[:change_password_post_redirect_id] = post_redirect.id
        put :update, :password_change_user => @valid_password_params,
                     :pretoken => pretoken.token
        expect(response).to redirect_to(pretoken.uri)
      end

      it 'does not redirect to another domain' do
        user = FactoryGirl.create(:user)
        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        pretoken = PostRedirect.create(:user => user, :uri => 'http://bad.place.com/')
        session[:change_password_post_redirect_id] = post_redirect.id
        put :update, :password_change_user => @valid_password_params,
                     :pretoken => pretoken.token
        expect(response).to redirect_to('/')
      end

      it 'redirects to the user profile with a blank pretoken' do
        user = FactoryGirl.create(:user)
        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        session[:change_password_post_redirect_id] = post_redirect.id
        put :update, :password_change_user => @valid_password_params,
                     :pretoken => ''
        expect(response).to redirect_to(show_user_profile_path(user.url_name))
      end

    end

    context 'when there is no pretoken' do

      it 'redirects to the user profile on success' do
        user = FactoryGirl.create(:user)
        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        session[:change_password_post_redirect_id] = post_redirect.id
        put :update, :password_change_user => @valid_password_params
        expect(response).to redirect_to(show_user_profile_path(user.url_name))
      end

    end

    it 're-renders the form on failure' do
      user = FactoryGirl.create(:user)
      post_redirect =
        PostRedirect.create(:user => user, :uri => frontpage_url)
      session[:change_password_post_redirect_id] = post_redirect.id
      put :update, :password_change_user => @invalid_password_params
      expect(response).to render_template(:edit)
    end

    context 'when the user has two factor authentication enabled' do

      it 'changes the password with a correct otp_code' do
        allow(AlaveteliConfiguration).
          to receive(:enable_two_factor_auth).and_return(true)

        user = FactoryGirl.build(:user)
        user.enable_otp
        user.save!

        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        session[:change_password_post_redirect_id] = post_redirect.id

        old_hash = user.hashed_password

        params = @valid_password_params.merge(:otp_code => user.otp_code)
        put :update, :password_change_user => params

        expect(user.reload.hashed_password).not_to eq(old_hash)
      end

      it 'redirects to the two factor page to show the new OTP' do
        allow(AlaveteliConfiguration).
          to receive(:enable_two_factor_auth).and_return(true)

        user = FactoryGirl.build(:user)
        user.enable_otp
        user.save!

        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        session[:change_password_post_redirect_id] = post_redirect.id

        old_hash = user.hashed_password

        params = @valid_password_params.merge(:otp_code => user.otp_code)
        put :update, :password_change_user => params

        expect(response).to redirect_to(one_time_password_path)
      end

      it 'redirects to the two factor page even if there is a pretoken redirect' do
        allow(AlaveteliConfiguration).
          to receive(:enable_two_factor_auth).and_return(true)

        user = FactoryGirl.build(:user)
        user.enable_otp
        user.save!

        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        pretoken = PostRedirect.create(:user => user, :uri => '/')
        session[:change_password_post_redirect_id] = post_redirect.id

        params = @valid_password_params.merge(:otp_code => user.otp_code)
        put :update, :password_change_user => params,
                     :pretoken => pretoken.token

        expect(response).to redirect_to(one_time_password_path)
      end

      it 'reminds the user that they have a new OTP' do
        allow(AlaveteliConfiguration).
          to receive(:enable_two_factor_auth).and_return(true)

        user = FactoryGirl.build(:user)
        user.enable_otp
        user.save!

        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        session[:change_password_post_redirect_id] = post_redirect.id

        old_hash = user.hashed_password

        params = @valid_password_params.merge(:otp_code => user.otp_code)
        put :update, :password_change_user => params

        msg = "Your password has been changed. " \
              "You also have a new one time passcode which you'll " \
              "need next time you want to change your password"
        expect(flash[:notice]).to eq(msg)
      end

      it 'does not change the password with an incorrect otp_code' do
        allow(AlaveteliConfiguration).
          to receive(:enable_two_factor_auth).and_return(true)

        user = FactoryGirl.build(:user)
        user.enable_otp
        user.save!

        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        session[:change_password_post_redirect_id] = post_redirect.id

        old_hash = user.hashed_password

        params = @valid_password_params.merge(:otp_code => 'invalid')
        put :update, :password_change_user => params

        expect(user.reload.hashed_password).to eq(old_hash)
      end

      it 'does not change the password without an otp_code' do
        allow(AlaveteliConfiguration).
          to receive(:enable_two_factor_auth).and_return(true)

        user = FactoryGirl.build(:user)
        user.enable_otp
        user.save!

        post_redirect =
          PostRedirect.create(:user => user, :uri => frontpage_url)
        session[:change_password_post_redirect_id] = post_redirect.id

        old_hash = user.hashed_password

        put :update, :password_change_user => @valid_password_params

        expect(user.reload.hashed_password).to eq(old_hash)
      end

    end

  end

end
