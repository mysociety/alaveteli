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

    it 'redirects back to #show' do
      session[:user_id] = @user.id
      post :create
      expect(response).to redirect_to(one_time_password_path)
    end

    context 'when 2factor auth is not enabled' do

      it 'raises ActiveRecord::RecordNotFound' do
        allow(AlaveteliConfiguration).
          to receive(:enable_2factor_auth).and_return(false)
        expect{ post :create }.to raise_error(ActiveRecord::RecordNotFound)
      end

    end
  end

end
