require 'spec_helper'

RSpec.describe Users::ConfirmationsController do
  describe 'GET confirm' do
    context 'if the post redirect cannot be found' do
      it 'renders bad_token' do
        get :confirm, params: { email_token: '' }
        expect(response).to render_template(:bad_token)
      end
    end

    context 'if the post redirect email token invalid' do
      it 'renders bad_token' do
        allow(PostRedirect).to receive(:find_by_email_token).with('abc').
          and_return(double(:post_redirect, email_token_valid?: false))
        get :confirm, params: { email_token: 'abc' }
        expect(response).to render_template(:bad_token)
      end
    end

    context 'the post redirect circumstance is change_password' do
      let(:user) { FactoryBot.create(:user, email_confirmed: false) }

      let(:post_redirect) do
        pr = PostRedirect.new(user: user, circumstance: 'change_password')
        pr.uri = edit_password_change_path(pr.token)
        pr.save!
        pr
      end

      before :each do
        get :confirm, params: { email_token: post_redirect.email_token }
      end

      it 'does not log the user in' do
        expect(session[:user_id]).to eq(nil)
      end

      it 'logs out a user who does not own the post redirect' do
        logged_in_user = FactoryBot.create(:user)
        pr = PostRedirect.new(user: user, circumstance: 'change_password')
        pr.uri = edit_password_change_path(pr.token)
        pr.save!

        sign_in logged_in_user

        get :confirm, params: { email_token: pr.email_token }
        expect(session[:user_id]).to be_nil
      end

      it 'does not log out a user if they own the post redirect' do
        pr = PostRedirect.new(user: user, circumstance: 'change_password')
        pr.uri = edit_password_change_path(pr.token)
        pr.save!

        sign_in user
        get :confirm, params: { email_token: pr.email_token }

        expect(session[:user_id]).to eq(user.id)
        expect(assigns[:user]).to eq(user)
      end

      it 'redirects to the post redirect uri' do
        expect(response).to redirect_to(
          "/profile/change_password/#{post_redirect.token}?post_redirect=1"
        )
      end

      context 'with a malicious post_redirect URI' do
        let(:post_redirect) do
          PostRedirect.create(
            user: user,
            circumstance: 'change_password',
            uri: 'http://example.com/blah'
          )
        end

        it 'does not redirect to another domain' do
          expect(response).to redirect_to('/blah?post_redirect=1')
        end
      end
    end

    context 'if the currently logged in user is an admin' do
      before :each do
        @admin = FactoryBot.create(:admin_user)
        @user = FactoryBot.create(:user, email_confirmed: false)
        @post_redirect = PostRedirect.create(uri: '/', user: @user)

        sign_in @admin
        get :confirm, params: { email_token: @post_redirect.email_token }
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

    context <<-EOF do
      if the currently logged in user is not an admin and owns the post
       redirect
    EOF

      before :each do
        @user = FactoryBot.create(:user, email_confirmed: false)
        @post_redirect = PostRedirect.create(uri: '/', user: @user)

        sign_in @user
        get :confirm, params: { email_token: @post_redirect.email_token }
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

    context <<-EOF do
      if the currently logged in user is not an admin and does not own the post
       redirect
    EOF
      before :each do
        @current_user = FactoryBot.create(:user)
        @user = FactoryBot.create(:user, email_confirmed: false)
        @post_redirect = PostRedirect.create(uri: '/', user: @user)

        sign_in @current_user
        get :confirm, params: { email_token: @post_redirect.email_token }
      end

      it 'does not confirm the post redirect user' do
        expect(@user.reload.email_confirmed).to eq(false)
      end

      it 'stays logged in as the current user' do
        expect(session[:user_id]).to eq(@current_user.id)
      end

      it 'renders wrong_user' do
        expect(response).to render_template('user/wrong_user')
      end
    end

    context 'if there is no logged in user' do
      before :each do
        @user = FactoryBot.create(:user, email_confirmed: false)
        @post_redirect = PostRedirect.create(uri: '/', user: @user)

        get :confirm, params: { email_token: @post_redirect.email_token }
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

    context 'if the post redirect user has TOTP two factor enabled' do
      let(:user) do
        FactoryBot.create(:user, :enable_totp, email_confirmed: false)
      end
      let(:post_redirect) { PostRedirect.create(uri: '/', user: user) }

      before :each do
        @original_token = post_redirect.email_token
        get :confirm, params: { email_token: @original_token }
      end

      it 'does not sign the user in' do
        expect(session[:user_id]).to be_nil
      end

      it 'redirects to the two factor challenge' do
        expect(response).to redirect_to(signin_two_factor_path)
      end

      it 'confirms the post redirect user' do
        expect(user.reload.email_confirmed).to eq(true)
      end

      it 'consumes the confirmation link before the challenge' do
        expect(PostRedirect.find_by(email_token: @original_token)).to be_nil
      end

      it 'stashes the pending sign-in for the challenge to resume' do
        expect(session[:pending_2fa_user_id]).to eq(user.id)
        expect(session[:pending_2fa_post_redirect_token]).
          to eq(post_redirect.token)
        expect(session[:pending_2fa_circumstance]).to eq('normal')
      end
    end

    context 'if the post redirect user has HOTP two factor enabled' do
      let(:user) do
        FactoryBot.create(:user, :enable_hotp, email_confirmed: false)
      end
      let(:post_redirect) { PostRedirect.create(uri: '/', user: user) }

      before :each do
        get :confirm, params: { email_token: post_redirect.email_token }
      end

      # HOTP is not a sign-in factor, so the confirmation link signs them in
      # directly rather than detouring to the challenge.
      it 'signs the user in without a two factor challenge' do
        expect(session[:user_id]).to eq(user.id)
        expect(response).not_to redirect_to(signin_two_factor_path)
      end
    end

    context 'token consumption' do
      it 'rotates the email token after successful confirmation' do
        user = FactoryBot.create(:user, email_confirmed: false)
        post_redirect = PostRedirect.create(uri: '/', user: user)
        original_token = post_redirect.email_token

        get :confirm, params: { email_token: original_token }
        expect(post_redirect.reload.email_token).not_to eq(original_token)
      end

      it 'prevents reuse of a consumed token' do
        user = FactoryBot.create(:user, email_confirmed: false)
        post_redirect = PostRedirect.create(uri: '/', user: user)
        original_token = post_redirect.email_token

        get :confirm, params: { email_token: original_token }

        found = PostRedirect.find_by(email_token: original_token)
        expect(found).to be_nil
      end
    end
  end
end
