# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Users::ConfirmationsController do

  describe 'GET confirm' do

    context 'if the post redirect cannot be found' do

      it 'renders bad_token' do
        get :confirm, { :email_token => '' }
        expect(response).to render_template(:bad_token)
      end

    end

    context 'the post redirect circumstance is login_as' do

      before :each do
        @user = FactoryGirl.create(:user, :email_confirmed => false)
        @post_redirect =
          PostRedirect.
            create(:uri => '/', :user => @user, :circumstance => 'login_as')

        get :confirm, { :email_token => @post_redirect.email_token }
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
        expect(response).to redirect_to('/?post_redirect=1&context=confirm')
      end

    end

    context 'the post redirect circumstance is change_password' do

      before :each do
        @user = FactoryGirl.create(:user)
        @post_redirect =
          PostRedirect.create(:uri => edit_password_change_path,
                              :user => @user,
                              :circumstance => 'change_password')

        get :confirm, { :email_token => @post_redirect.email_token }
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
        get :confirm, { :email_token => @post_redirect.email_token }

        expect(session[:user_id]).to be_nil
      end

      it 'does not log out a user if they own the post redirect' do
        @user = FactoryGirl.create(:user, :email_confirmed => false)
        @post_redirect =
          PostRedirect.create(:uri => edit_password_change_path,
                              :user => @user,
                              :circumstance => 'change_password')

        session[:user_id] = @user.id
        get :confirm, { :email_token => @post_redirect.email_token }

        expect(session[:user_id]).to eq(@user.id)
        expect(assigns[:user]).to eq(@user)
      end

      it 'does not confirm an unconfirmed user' do
        @user = FactoryGirl.create(:user, :email_confirmed => false)
        @post_redirect =
          PostRedirect.create(:uri => edit_password_change_path,
                              :user => @user,
                              :circumstance => 'change_password')

        get :confirm, { :email_token => @post_redirect.email_token }

        expect(@user.reload.email_confirmed).to eq(false)
      end

      it 'sets the user_circumstance to change_password' do
        expect(session[:user_circumstance]).to eq('change_password')
      end

      it 'redirects to the post redirect uri' do
        expect(response).
          to redirect_to('/profile/change_password?' \
                         'post_redirect=1&context=confirm')
      end

    end

    context 'if the currently logged in user is an admin' do

      before :each do
        @admin = FactoryGirl.create(:admin_user)
        @user = FactoryGirl.create(:user, :email_confirmed => false)
        @post_redirect = PostRedirect.create(:uri => '/', :user => @user)

        session[:user_id] = @admin.id
        get :confirm, { :email_token => @post_redirect.email_token }
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
        expect(response).to redirect_to('/?post_redirect=1&context=confirm')
      end

    end

    context <<-EOF do
      if the currently logged in user is not an admin and owns the post
       redirect
    EOF

      before :each do
        @user = FactoryGirl.create(:user, :email_confirmed => false)
        @post_redirect = PostRedirect.create(:uri => '/', :user => @user)

        session[:user_id] = @user.id
        get :confirm, { :email_token => @post_redirect.email_token }
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
        expect(response).to redirect_to('/?post_redirect=1&context=confirm')
      end

    end

    context <<-EOF do
      if the currently logged in user is not an admin and does not own the post
       redirect
    EOF
      before :each do
        @current_user = FactoryGirl.create(:user)
        @user = FactoryGirl.create(:user, :email_confirmed => false)
        @post_redirect = PostRedirect.create(:uri => '/', :user => @user)

        session[:user_id] = @current_user.id
        get :confirm, { :email_token => @post_redirect.email_token }
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
        expect(response).to redirect_to('/?post_redirect=1&context=confirm')
      end

    end

    context 'if there is no logged in user' do

      before :each do
        @user = FactoryGirl.create(:user, :email_confirmed => false)
        @post_redirect = PostRedirect.create(:uri => '/', :user => @user)

        get :confirm, { :email_token => @post_redirect.email_token }
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
        expect(response).to redirect_to('/?post_redirect=1&context=confirm')
      end

    end
  end
end
