# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliPro::SubscriptionsController do

  describe 'POST #create' do

    context 'without a signed-in user' do

      before do
        post :create
      end

      it 'redirects to the login form' do
        expect(response).
          to redirect_to(signin_path(:token => PostRedirect.last.token))
      end

    end

    context 'with a signed-in user' do
      let(:user) { FactoryGirl.create(:user) }

      before do
        session[:user_id] = user.id
        post :create
      end

      it 'redirects to the pro dashboard' do
        expect(response).to redirect_to(alaveteli_pro_dashboard_path)
      end

    end

  end

end
