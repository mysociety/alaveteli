# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PasswordChangesController do

  describe 'GET new' do

    it 'assigns the pretoken if supplied' do
      get :new, params: { :pretoken => 'abcdef' }
      expect(assigns[:pretoken]).to eq('abcdef')
    end

    it 'assigns nil to the pretoken if not supplied' do
      get :new
      expect(assigns[:pretoken]).to eq(nil)
    end

    it 'assigns nil to the pretoken if blank' do
      get :new, params: { :pretoken => '' }
      expect(assigns[:pretoken]).to eq(nil)
    end

    it 'does not pre-fill the email field without a signed in user' do
      get :new
      expect(assigns[:email_field_options]).to eq({})
    end

    it 'pre-fills the email field for a signed in user' do
      user = FactoryBot.create(:user)
      session[:user_id] = user.id
      get :new
      expect(assigns[:email_field_options][:value]).to eq(user.email)
    end

    it 'disables the email field for a signed in user' do
      user = FactoryBot.create(:user)
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
        user = FactoryBot.create(:user)
        session[:user_id] = user.id
        post :create, params: { :password_change_user => { :email => 'hacker@localhost' } }
        expect(assigns[:password_change_user]).to eq(user)
      end

      it 'does not require an email to be submitted' do
        user = FactoryBot.create(:user)
        session[:user_id] = user.id
        post :create
        expect(assigns[:password_change_user]).to eq(user)
      end
    end

    context 'when no user is signed in and no email is submitted' do

      it 're-renders the form' do
        post :create
        expect(response).to render_template(:new)
      end

    end

    context 'when receiving an email address of an existing user' do

      it 'assigns the user' do
        user = FactoryBot.create(:user)
        post :create, params: { :password_change_user => { :email => user.email } }
        expect(assigns[:password_change_user]).to eq(user)
      end

      it 'finds the user if the email case is different' do
        user = FactoryBot.create(:user)
        post :create, params: { :password_change_user => { :email => user.email.upcase } }
        expect(assigns[:password_change_user]).to eq(user)
      end

      it 'creates a post redirect' do
        user = FactoryBot.create(:user)
        expected_attrs =
          { :post_params => {},
            :reason_params => {
              :web => '',
              :email => _('Then you can change your password on {{site_name}}',
                          :site_name => AlaveteliConfiguration.site_name),
              :email_subject => _('Change your password on {{site_name}}',
                                  :site_name =>
                                    AlaveteliConfiguration.site_name) },
            :circumstance => 'change_password' }

        post :create, params: { :password_change_user => { :email => user.email } }

        post_redirect = PostRedirect.last
        expected_attrs[:uri] = edit_password_change_url(post_redirect.token)

        post_redirect_attrs = { :uri => post_redirect.uri,
                                :post_params => post_redirect.post_params,
                                :reason_params => post_redirect.reason_params,
                                :circumstance => post_redirect.circumstance }

        expect(post_redirect_attrs).to eq(expected_attrs)
      end

      context 'when a pretoken is supplied' do

        it 'adds the pretoken to the post redirect uri' do
          user = FactoryBot.create(:user)
          pretoken = PostRedirect.create(:user => user, :uri => '/')
          post :create, params: { :password_change_user => { :email => user.email }, :pretoken => pretoken.token }
          post_redirect = PostRedirect.last
          expected = edit_password_change_url(post_redirect.token,
                                              :pretoken => pretoken.token)
          expect(post_redirect.uri).to include(expected)
        end

        it 'does not add a blank pretoken to the post redirect uri' do
          user = FactoryBot.create(:user)
          pretoken = PostRedirect.create(:user => user, :uri => '/')
          post :create, params: { :password_change_user => { :email => user.email }, :pretoken => '' }
          post_redirect = PostRedirect.last
          expected = edit_password_change_url(post_redirect.token)
          expect(post_redirect.uri).to eq(expected)
        end

      end

      it 'sends a confirmation email' do
        user = FactoryBot.create(:user)

        post :create, params: { :password_change_user => { :email => user.email } }

        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq('Change your password on Alaveteli')
        ActionMailer::Base.deliveries.clear
      end

      it 'does not send a confirmation email for an unknown email' do
        post :create, params: { :password_change_user => { :email => 'unknown-email@example.org' } }
        expect(ActionMailer::Base.deliveries.size).to eq(0)
      end

      it 'renders the confirmation message' do
        user = FactoryBot.create(:user)
        post :create, params: { :password_change_user => { :email => user.email } }
        expect(response).to render_template(:check_email)
      end

      it 'renders the confirmation message for an unknown email' do
        post :create, params: { :password_change_user => { :email => 'unknown-email@example.org' } }
        expect(response).to render_template(:check_email)
      end

      it 'warns the user of an invalid email format' do
        msg = "That doesn't look like a valid email address. Please check " \
              "you have typed it correctly."
        post :create, params: { :password_change_user => { :email => 'invalid-email' } }
        expect(flash[:error]).to eq(msg)
      end

      it 're-renders the form with an invalid email format' do
        post :create, params: { :password_change_user => { :email => 'invalid-email' } }
        expect(response).to render_template(:new)
      end

    end

  end

  describe 'GET edit' do

    let(:user) { FactoryBot.create(:user) }
    let(:post_redirect) do
      PostRedirect.create(:user => user, :uri => frontpage_url)
    end

    it 'assigns the pretoken if supplied' do
      get :edit, params: { :id => post_redirect.token, :pretoken => 'abcdef' }
      expect(assigns[:pretoken]).to eq('abcdef')
    end

    it 'assigns nil to the pretoken if not supplied' do
      get :edit, params: { :id => post_redirect.token }
      expect(assigns[:pretoken]).to eq(nil)
    end

    it 'assigns nil to the pretoken if blank' do
      get :edit, params: { :id => post_redirect.token, :pretoken => '' }
      expect(assigns[:pretoken]).to eq(nil)
    end

    it 'assigns the user' do
      get :edit, params: { :id => post_redirect.token }
      expect(assigns[:password_change_user]).to eq(user)
    end

    context 'no user is specified' do

      let(:post_redirect) { PostRedirect.new(user: nil) }

      it 'redirects to new for the user to enter their email' do
        get :edit, params: { :id => post_redirect.token }
        expect(response).to redirect_to(new_password_change_path)
      end

      it 'redirects to new with a pretoken for the user to enter their email' do
        get :edit, params: { :id => post_redirect.token, :pretoken => 'abcdef' }
        expect(response).
          to redirect_to(new_password_change_path(:pretoken => 'abcdef'))
      end

    end

    context 'invalid token' do

      it 'redirects to new to force an email confirmation' do
        get :edit, params: { :id => 'invalid' }
        expect(response).to redirect_to new_password_change_path
      end

    end

  end

  describe 'PUT update' do

    let(:user) { FactoryBot.create(:user) }
    let(:post_redirect) do
      PostRedirect.create(:user => user, :uri => frontpage_path)
    end

    before(:each) do
      @valid_password_params =
        { :password => 'secret123456',
          :password_confirmation => 'secret123456' }
      @invalid_password_params =
        { :password => 'secret',
          :password_confirmation => 'password' }
    end

    it 'changes the password on success' do
      old_hash = user.hashed_password
      put :update, params: { :id => post_redirect.token, :password_change_user => @valid_password_params }
      expect(user.reload.hashed_password).not_to eq(old_hash)
    end

    it 'notifies the user the password change has been successful' do
      put :update, params: { :id => post_redirect.token, :password_change_user => @valid_password_params }
      expect(flash[:notice]).to eq('Your password has been changed.')
    end

    it 'assigns the user from a post redirect' do
      put :update, params: { :id => post_redirect.token, :password_change_user => @valid_password_params }
      expect(assigns[:password_change_user]).to eq(user)
    end

    it 'logs in the user on success' do
      put :update, params: { :id => post_redirect.token, :password_change_user => @valid_password_params }
      expect(session[:user_id]).to eq(user.id)
    end

    it 'retains the old password on failure' do
      old_hash = user.hashed_password
      put :update, params: { :id => post_redirect.token, :password_change_user => @invalid_password_params }
      expect(user.reload.hashed_password).to eq(old_hash)
    end

    it 're-renders the form on failure' do
      put :update, params: { :id => post_redirect.token, :password_change_user => @invalid_password_params }
      expect(response).to render_template(:edit)
    end

    context 'no user is specified' do

      let(:post_redirect) { PostRedirect.new(:user => nil) }

      it 'redirects to #new when a user cannot be found' do
        put :update, params: { :id => post_redirect.token, :password_change_user => @valid_password_params }
        expect(response).to redirect_to(new_password_change_path)
      end

    end

    context 'invalid token' do

      it 'redirects to new to force an email confirmation' do
        put :update, params: { :id => 'invalid', :password_change_user => @valid_password_params }
        expect(response).to redirect_to new_password_change_path
      end

    end

    context 'when a pretoken is supplied' do

      it 'redirects to the post redirect uri' do
        pretoken = PostRedirect.create(:user => user, :uri => '/')
        put :update, params: { :id => post_redirect.token, :password_change_user => @valid_password_params, :pretoken => pretoken.token }
        expect(response).to redirect_to(pretoken.uri)
      end

      it 'does not redirect to another domain' do
        pretoken = PostRedirect.create(:user => user, :uri => 'http://bad.place.com/')
        put :update, params: { :id => post_redirect.token, :password_change_user => @valid_password_params, :pretoken => pretoken.token }
        expect(response).to redirect_to('/')
      end

      it 'redirects to the user profile with a blank pretoken' do
        put :update, params: { :id => post_redirect.token, :password_change_user => @valid_password_params, :pretoken => '' }
        expect(response).to redirect_to(show_user_profile_path(user.url_name))
      end

    end

    context 'when there is no pretoken' do

      it 'redirects to the user profile on success' do
        put :update, params: { :id => post_redirect.token, :password_change_user => @valid_password_params }
        expect(response).to redirect_to(show_user_profile_path(user.url_name))
      end

    end

    context 'when the user has two factor authentication enabled' do

      let(:user) { FactoryBot.create(:user, :enable_otp) }

      before(:each) do
        allow(AlaveteliConfiguration).
          to receive(:enable_two_factor_auth).and_return(true)
      end

      it 'changes the password with a correct otp_code' do
        old_hash = user.hashed_password
        params = @valid_password_params.merge(:otp_code => user.otp_code)
        put :update, params: { :id => post_redirect.token, :password_change_user => params }

        expect(user.reload.hashed_password).not_to eq(old_hash)
      end

      it 'redirects to the two factor page to show the new OTP' do
        old_hash = user.hashed_password
        params = @valid_password_params.merge(:otp_code => user.otp_code)
        put :update, params: { :id => post_redirect.token, :password_change_user => params }

        expect(response).to redirect_to(one_time_password_path)
      end

      it 'redirects to the two factor page even if there is a pretoken redirect' do
        pretoken = PostRedirect.create(:user => user, :uri => '/')
        params = @valid_password_params.merge(:otp_code => user.otp_code)
        put :update, params: { :id => post_redirect.token, :password_change_user => params, :pretoken => pretoken.token }

        expect(response).to redirect_to(one_time_password_path)
      end

      it 'reminds the user that they have a new OTP' do
        old_hash = user.hashed_password
        params = @valid_password_params.merge(:otp_code => user.otp_code)
        put :update, params: { :id => post_redirect.token, :password_change_user => params }

        msg = "Your password has been changed. " \
              "You also have a new one time passcode which you'll " \
              "need next time you want to change your password"
        expect(flash[:notice]).to eq(msg)
      end

      it 'does not change the password with an incorrect otp_code' do
        old_hash = user.hashed_password
        params = @valid_password_params.merge(:otp_code => 'invalid')
        put :update, params: { :id => post_redirect.token, :password_change_user => params }

        expect(user.reload.hashed_password).to eq(old_hash)
      end

      it 'does not change the password without an otp_code' do
        old_hash = user.hashed_password
        put :update, params: { :id => post_redirect.token, :password_change_user => @valid_password_params }

        expect(user.reload.hashed_password).to eq(old_hash)
      end

    end

  end

end
