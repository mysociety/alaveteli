# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'stripe_mock'

describe AlaveteliPro::SubscriptionsController do
  let(:stripe_helper) { StripeMock.create_test_helper }

  before do
    StripeMock.start
    stripe_helper.create_plan(id: 'pro', amount: 1000)
  end

  after do
    StripeMock.stop
  end

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
      let(:token) { stripe_helper.generate_card_token }

      before do
        session[:user_id] = user.id
        session[:user_id] = user.id
        post :create, 'stripeToken' => token,
                      'stripeTokenType' => 'card',
                      'stripeEmail' => user.email,
                      'plan_id' => 'pro'
      end

      it 'finds the token' do
        expect(assigns(:token).id).to eq(token)
      end

      it 'creates a new Stripe customer' do
        expect(assigns(:customer).email).to eq(user.email)
      end

      it 'subscribes the user to the plan' do
        expected = { user: assigns(:customer).id,
                     plan: 'pro' }
        actual = { user: assigns(:subscription).customer,
                   plan: assigns(:subscription).plan.id }
        expect(actual).to eq(expected)
      end

      it 'creates a pro account for the user' do
        expect(user.pro_account).to be_present
      end

      it 'stores the stripe_customer_id in the pro_account' do
        expect(user.pro_account.stripe_customer_id).
          to eq(assigns(:customer).id)
      end

      it 'redirects to the pro dashboard' do
        expect(response).to redirect_to(alaveteli_pro_dashboard_path)
      end

    end

  end

end
