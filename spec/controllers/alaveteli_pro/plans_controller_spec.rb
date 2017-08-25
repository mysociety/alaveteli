# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'stripe_mock'

describe AlaveteliPro::PlansController do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let!(:pro_plan) { stripe_helper.create_plan(id: 'pro', amount: 1000) }

  describe 'GET #show' do

    context 'without a signed-in user' do

      before do
        get :show, id: 'pro'
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
        get :show, id: 'pro'
      end

      it 'finds the specified plan' do
        expect(assigns(:plan)).to eq(pro_plan)
      end

      it 'renders the plan page' do
        expect(response).to render_template(:show)
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

    end

  end

end
