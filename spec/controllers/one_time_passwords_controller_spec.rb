# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OneTimePasswordsController do

  before do
    @user = FactoryGirl.create(:user)
    allow(AlaveteliConfiguration).
      to receive(:enable_2factor_auth).and_return(true)
  end

  describe 'GET #show' do

    it 'redirects to the sign-in page without a signed in user' do
      get :show
      expect(response).
        to redirect_to(signin_path(:token => PostRedirect.last.token))
    end

    it 'assigns the signed in user' do
      session[:user_id] = @user.id
      get :show
      expect(assigns[:user]).to eq(@user)
    end

    it 'renders the show template' do
      session[:user_id] = @user.id
      get :show
      expect(response).to render_template('show')
    end

    context 'when 2factor auth is not enabled' do

      it 'raises ActiveRecord::RecordNotFound' do
        allow(AlaveteliConfiguration).
          to receive(:enable_2factor_auth).and_return(false)
        expect{ get :show }.to raise_error(ActiveRecord::RecordNotFound)
      end

    end

  end

  describe 'POST #create' do

    it 'redirects to the sign-in page without a signed in user' do
      post :create
      expect(response).
        to redirect_to(signin_path(:token => PostRedirect.last.token))
    end

    it 'assigns the signed in user' do
      session[:user_id] = @user.id
      post :create
      expect(assigns[:user]).to eq(@user)
    end

    it 'enables OTP for the user' do
      session[:user_id] = @user.id
      post :create
      expect(@user.reload.otp_enabled?).to eq(true)
    end

    it 'sets a successful notification message' do
      session[:user_id] = @user.id
      post :create
      expect(flash[:notice]).to eq('2factor authentication enabled')
    end

    it 'redirects back to #show on success' do
      session[:user_id] = @user.id
      post :create
      expect(response).to redirect_to(one_time_password_path)
    end

    it 'renders #show on failure' do
      allow_any_instance_of(User).to receive(:save).and_return(false)
      session[:user_id] = @user.id
      post :create
      expect(response).to render_template('show')
    end

    context 'when 2factor auth is not enabled' do

      it 'raises ActiveRecord::RecordNotFound' do
        allow(AlaveteliConfiguration).
          to receive(:enable_2factor_auth).and_return(false)
        expect{ post :create }.to raise_error(ActiveRecord::RecordNotFound)
      end

    end

  end

  describe 'PUT #update' do

    it 'redirects to the sign-in page without a signed in user' do
      put :update
      expect(response).
        to redirect_to(signin_path(:token => PostRedirect.last.token))
    end

    it 'assigns the signed in user' do
      session[:user_id] = @user.id
      put :update
      expect(assigns[:user]).to eq(@user)
    end

    it 'regenerates the otp_code' do
      @user.enable_otp
      @user.save!
      expected = ROTP::HOTP.new(@user.otp_secret_key).at(2)
      session[:user_id] = @user.id
      put :update
      expect(@user.reload.otp_code).to eq(expected)
    end

    it 'sets a successful notification message' do
      session[:user_id] = @user.id
      put :update
      expect(flash[:notice]).to eq('2factor one time password updated')
    end

    it 'redirects back to #show on success' do
      session[:user_id] = @user.id
      put :update
      expect(response).to redirect_to(one_time_password_path)
    end

    it 'renders #show on failure' do
      allow_any_instance_of(User).to receive(:save).and_return(false)
      session[:user_id] = @user.id
      put :update
      expect(response).to render_template('show')
    end

    context 'when 2factor auth is not enabled' do

      it 'raises ActiveRecord::RecordNotFound' do
        allow(AlaveteliConfiguration).
          to receive(:enable_2factor_auth).and_return(false)
        expect{ put :update }.to raise_error(ActiveRecord::RecordNotFound)
      end

    end

  end

  describe 'DELETE #destroy' do

    it 'redirects to the sign-in page without a signed in user' do
      delete :destroy
      expect(response).
        to redirect_to(signin_path(:token => PostRedirect.last.token))
    end

    it 'assigns the signed in user' do
      session[:user_id] = @user.id
      delete :destroy
      expect(assigns[:user]).to eq(@user)
    end

    it 'disables OTP for the user' do
      @user.enable_otp
      @user.save!
      session[:user_id] = @user.id
      delete :destroy
      expect(@user.reload.otp_enabled?).to eq(false)
    end

    it 'redirects back to #show on success' do
      session[:user_id] = @user.id
      delete :destroy
      expect(response).to redirect_to(one_time_password_path)
    end

    it 'renders #show on failure' do
      allow_any_instance_of(User).to receive(:save).and_return(false)
      session[:user_id] = @user.id
      delete :destroy
      expect(response).to render_template('show')
    end

    context 'when 2factor auth is not enabled' do

      it 'raises ActiveRecord::RecordNotFound' do
        allow(AlaveteliConfiguration).
          to receive(:enable_2factor_auth).and_return(false)
        expect{ delete :destroy }.to raise_error(ActiveRecord::RecordNotFound)
      end

    end

  end

end
