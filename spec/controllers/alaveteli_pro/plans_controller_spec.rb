# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'stripe_mock'

describe AlaveteliPro::PlansController do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let!(:pro_plan) { stripe_helper.create_plan(id: 'pro', amount: 1000) }
  let!(:alaveteli_pro_plan) do
    stripe_helper.create_plan(id: 'alaveteli-pro', amount: 1000)
  end

  describe 'GET #index' do

    before do
      get :index
    end

    it 'renders the plans page' do
      expect(response).to render_template(:index)
    end

    it 'returns http success' do
      expect(response).to be_successful
    end

    it 'sets in_pro_area' do
      expect(assigns(:in_pro_area)).to be true
    end

    it 'sets pro_site_name' do
      expect(assigns(:pro_site_name)).to eq AlaveteliConfiguration.pro_site_name
    end

    it 'uses the default plan for pricing info' do
      expect(assigns(:plan)).to eq(pro_plan)
    end
  end

  describe 'GET #show' do

    context 'without a signed-in user' do

      before do
        get :show, params: { id: 'pro' }
      end

      it 'redirects to the login form' do
        expect(response).
          to redirect_to(signin_path(:token => PostRedirect.last.token))
      end

      it 'sets in_pro_area' do
        expect(assigns(:in_pro_area)).to be true
      end

    end

    context 'with a signed-in user' do
      let(:user) { FactoryBot.create(:user) }

      before do
        session[:user_id] = user.id
      end

      context 'with a valid plan' do

        before do
          get :show, params: { id: 'pro' }
        end

        it 'finds the specified plan' do
          expect(assigns(:plan)).to eq(pro_plan)
        end

        it 'renders the plan page' do
          expect(response).to render_template(:show)
        end

        it 'returns http success' do
          expect(response).to be_successful
        end

      end

      context 'with a Stripe namespace' do

        before do
          allow(AlaveteliConfiguration).to receive(:stripe_namespace).
            and_return('alaveteli')
          get :show, params: { id: 'pro' }
        end

        it 'finds the specified plan' do
          expect(assigns(:plan)).to eq(alaveteli_pro_plan)
        end

        it 'renders the plan page' do
          expect(response).to render_template(:show)
        end

        it 'returns http success' do
          expect(response).to be_successful
        end

      end

      context 'with an existing subscription' do

        before do
          session[:user_id] = user.id
          customer =
            Stripe::Customer.create(email: user.email,
                                    source: stripe_helper.generate_card_token)

          Stripe::Subscription.create(customer: customer, plan: 'pro')
          user.create_pro_account(:stripe_customer_id => customer.id)
          user.add_role(:pro)
          get :show, params: { id: 'pro' }
        end

        it 'tells the user they already have a plan' do
          expect(flash[:error]).to eq('You are already subscribed to this plan')
        end

        it 'redirects to the account page' do
          expect(response).to redirect_to(subscriptions_path)
        end
      end

      context 'with an existing customer id but no active subscriptions' do

        before do
          session[:user_id] = user.id
          customer =
            Stripe::Customer.create(email: user.email,
                                    source: stripe_helper.generate_card_token)

          subscription =
            Stripe::Subscription.create(customer: customer, plan: 'pro')

          subscription.delete
          user.create_pro_account(:stripe_customer_id => customer.id)
          get :show, params: { id: 'pro' }
        end

        it 'renders the plan page' do
          expect(response).to render_template(:show)
        end

        it 'returns http success' do
          expect(response).to be_successful
        end

      end

      context 'with an invalid plan' do

        it 'returns ActiveRecord::RecordNotFound' do
          expect {
            get :show, params: { id: 'invalid-123' }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end

      end

    end

  end

end
