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
      end

      context 'with a valid plan' do

        before do
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

      context 'with an existing subscription' do

        before do
          session[:user_id] = user.id
          customer =
            Stripe::Customer.create(email: user.email,
                                    source: stripe_helper.generate_card_token)

          Stripe::Subscription.create(customer: customer, plan: 'pro')
          user.create_pro_account(:stripe_customer_id => customer.id)
          user.add_role(:pro)
          get :show, id: 'pro'
        end

        it 'tells the user they already have a plan' do
          expect(flash[:error]).to eq('You are already subscribed to this plan')
        end

        it 'redirects to the pro dashboard' do
          expect(response).to redirect_to(alaveteli_pro_dashboard_path)
        end

        pending 'redirects to the account page' do
          expect(response).to redirect_to(users_subscriptions_path)
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
          get :show, id: 'pro'
        end

        it 'renders the plan page' do
          expect(response).to render_template(:show)
        end

        it 'returns http success' do
          expect(response).to have_http_status(:success)
        end

      end

      context 'with an invalid plan' do

        it 'returns ActiveRecord::RecordNotFound' do
          expect { get :show, id: 'invalid-123' }.
            to raise_error(ActiveRecord::RecordNotFound)
        end

      end

    end

  end

end
