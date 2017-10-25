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

      before do
        session[:user_id] = user.id
      end

      context 'with a successful transaction' do
        let(:token) { stripe_helper.generate_card_token }

        before do
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

        it 'welcomes the new user' do
          expect(flash[:notice]).to eq('Welcome to Alaveteli Professional!')
        end

        it 'redirects to the pro dashboard' do
          expect(response).to redirect_to(alaveteli_pro_dashboard_path)
        end

      end

      context 'with an existing customer but no active subscriptions' do
        let(:token) { stripe_helper.generate_card_token }

        before do
          customer =
            Stripe::Customer.create(email: user.email,
                                    source: stripe_helper.generate_card_token)
          user.create_pro_account(:stripe_customer_id => customer.id)

          post :create, 'stripeToken' => token,
                        'stripeTokenType' => 'card',
                        'stripeEmail' => user.email,
                        'plan_id' => 'pro'
        end

        it 'uses the existing stripe customer record' do
          customers = Stripe::Customer.list.map(&:id)
          expect(customers).to eq([user.pro_account.stripe_customer_id])
        end

        it 'updates the source from the new token' do
          expect(assigns[:customer].default_source).
            to eq(assigns[:token].card.id)
        end
      end

      context 'when the card is declined' do
        let(:token) { stripe_helper.generate_card_token }

        before do
          StripeMock.prepare_card_error(:card_declined, :create_subscription)
          post :create, 'stripeToken' => token,
                        'stripeTokenType' => 'card',
                        'stripeEmail' => user.email,
                        'plan_id' => 'pro'
        end

        it 'renders the card error message' do
          expect(flash[:error]).to eq('The card was declined')
        end

        it 'redirects to the plan page' do
          expect(response).to redirect_to(plan_path('pro'))
        end

      end

      context 'when we are rate limited' do
        let(:token) { stripe_helper.generate_card_token }

        before do
          error = Stripe::RateLimitError.new
          StripeMock.prepare_error(error, :create_subscription)
          post :create, 'stripeToken' => token,
                        'stripeTokenType' => 'card',
                        'stripeEmail' => user.email,
                        'plan_id' => 'pro'
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::RateLimitError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the plan page' do
          expect(response).to redirect_to(plan_path('pro'))
        end

      end

      context 'when Stripe receives an invalid request' do
        let(:token) { stripe_helper.generate_card_token }

        before do
          error = Stripe::InvalidRequestError.new('message', 'param')
          StripeMock.prepare_error(error, :create_subscription)
          post :create, 'stripeToken' => token,
                        'stripeTokenType' => 'card',
                        'stripeEmail' => user.email,
                        'plan_id' => 'pro'
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::InvalidRequestError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the plan page' do
          expect(response).to redirect_to(plan_path('pro'))
        end

      end

      context 'when we cannot authenticate with Stripe' do
        let(:token) { stripe_helper.generate_card_token }

        before do
          error = Stripe::AuthenticationError.new
          StripeMock.prepare_error(error, :create_subscription)
          post :create, 'stripeToken' => token,
                        'stripeTokenType' => 'card',
                        'stripeEmail' => user.email,
                        'plan_id' => 'pro'
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::AuthenticationError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the plan page' do
          expect(response).to redirect_to(plan_path('pro'))
        end

      end

      context 'when we cannot connect to Stripe' do
        let(:token) { stripe_helper.generate_card_token }

        before do
          error = Stripe::APIConnectionError.new
          StripeMock.prepare_error(error, :create_subscription)
          post :create, 'stripeToken' => token,
                        'stripeTokenType' => 'card',
                        'stripeEmail' => user.email,
                        'plan_id' => 'pro'
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::APIConnectionError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the plan page' do
          expect(response).to redirect_to(plan_path('pro'))
        end

      end

      context 'when Stripe returns a generic error' do
        let(:token) { stripe_helper.generate_card_token }

        before do
          error = Stripe::StripeError.new
          StripeMock.prepare_error(error, :create_subscription)
          post :create, 'stripeToken' => token,
                        'stripeTokenType' => 'card',
                        'stripeEmail' => user.email,
                        'plan_id' => 'pro'
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::StripeError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the plan page' do
          expect(response).to redirect_to(plan_path('pro'))
        end

      end

      context 'when invalid params are submitted' do

        it 'redirects to the plan page if there is a plan' do
          post :create, :plan_id => 'pro'
          expect(response).to redirect_to(plan_path('pro'))
        end

        pending 'redirects to the pricing page if there is no plan' do
          post :create
          expect(response).to redirect_to(plans_path)
        end

      end

    end

  end

  describe 'GET #show' do

    context 'without a signed-in user' do

      before do
        get :show
      end

      it 'redirects to the login form' do
        expect(response).
          to redirect_to(signin_path(:token => PostRedirect.last.token))
      end

    end

    context 'user has no Stripe id' do

      let(:user) { FactoryGirl.create(:pro_user) }

      before do
        session[:user_id] = user.id
      end

      it 'raise an error' do
        expect { get :show }.to raise_error ActiveRecord::RecordNotFound
      end

    end

    context 'with a signed-in user' do

      let(:user) { FactoryGirl.create(:pro_user) }

      let!(:customer) do
        plan = stripe_helper.create_plan(id: 'test')
        customer = Stripe::Customer.create({
          email: user.email,
          source: stripe_helper.generate_card_token,
          plan: 'test'
        })
        user.pro_account.update!(stripe_customer_id: customer.id)
        customer
      end

      before do
        session[:user_id] = user.id
        get :show
      end

      it 'successfully loads the page' do
        get :show
        expect(response).to be_success
      end

      it 'finds the Stripe subscription for the user' do
        expect(assigns[:customer].id).
          to eq(user.pro_account.stripe_customer_id)
      end

      it 'assigns subscriptions' do
        expect(assigns[:subscriptions].length).to eq(1)
        expect(assigns[:subscriptions].first.id).
          to eq(customer.subscriptions.first.id)
      end

      it 'assigns the default source as card' do
        expect(assigns[:card].id).to eq(customer.default_source)
      end

    end

  end

  describe 'DELETE #destroy' do

    context 'without a signed-in user' do

      before do
        delete :destroy, id: '123'
      end

      it 'redirects to the login form' do
        expect(response).
          to redirect_to(signin_path(:token => PostRedirect.last.token))
      end

    end

    context 'user has no Stripe id' do

      let(:user) { FactoryGirl.create(:pro_user) }

      before do
        session[:user_id] = user.id
      end

      it 'raise an error' do
        expect { delete :destroy, id: '123' }.
          to raise_error ActiveRecord::RecordNotFound
      end

    end

    context 'with a signed-in user' do

      let(:user) { FactoryGirl.create(:pro_user) }

      let(:plan) { stripe_helper.create_plan(id: 'test') }

      let(:customer) do
        customer = Stripe::Customer.create({
          email: user.email,
          source: stripe_helper.generate_card_token,
        })
        user.pro_account.update!(stripe_customer_id: customer.id)
        customer
      end

      let(:subscription) do
        Stripe::Subscription.create(customer: customer, plan: plan.id)
      end

      before do
        session[:user_id] = user.id
        delete :destroy, id: subscription.id
      end

      it 'finds the subscription in Stripe' do
        expect(assigns[:subscription].id).to eq(subscription.id)
      end

      it 'cancels the subscription at the end of the billing period' do
        expect(assigns[:subscription].cancel_at_period_end).to eq(true)
      end

      it 'informs the user that they have cancelled' do
        msg = 'You have successfully cancelled your subscription to ' \
              'Alaveteli Professional'
        expect(flash[:notice]).to eq(msg)
      end

      it 'redirects to the subscriptions page' do
        expect(response).to redirect_to(profile_subscription_path)
      end

      context 'when destroying a subscription belonging to another user' do

        let(:other_subscription) do
          customer = Stripe::Customer.create({
            email: 'test@example.org',
            source: stripe_helper.generate_card_token,
          })
          Stripe::Subscription.create(customer: customer, plan: plan.id)
        end

        it 'raises an error' do
          session[:user_id] = user.id
          expect { delete :destroy, id: other_subscription.id }.
            to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'when we are rate limited' do

        before do
          error = Stripe::RateLimitError.new
          StripeMock.prepare_error(error, :cancel_subscription)
          delete :destroy, id: subscription.id
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::RateLimitError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the subscriptions page' do
          expect(response).to redirect_to(profile_subscription_path)
        end

      end

      context 'when Stripe receives an invalid request' do

        before do
          error = Stripe::InvalidRequestError.new('message', 'param')
          StripeMock.prepare_error(error, :cancel_subscription)
          delete :destroy, id: subscription.id
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::InvalidRequestError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the subscriptions page' do
          expect(response).to redirect_to(profile_subscription_path)
        end

      end

      context 'when we cannot authenticate with Stripe' do

        before do
          error = Stripe::AuthenticationError.new
          StripeMock.prepare_error(error, :cancel_subscription)
          delete :destroy, id: subscription.id
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::AuthenticationError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the subscriptions page' do
          expect(response).to redirect_to(profile_subscription_path)
        end

      end

      context 'when we cannot connect to Stripe' do

        before do
          error = Stripe::APIConnectionError.new
          StripeMock.prepare_error(error, :cancel_subscription)
          delete :destroy, id: subscription.id
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::APIConnectionError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the subscriptions page' do
          expect(response).to redirect_to(profile_subscription_path)
        end

      end

      context 'when Stripe returns a generic error' do

        before do
          error = Stripe::StripeError.new
          StripeMock.prepare_error(error, :cancel_subscription)
          delete :destroy, id: subscription.id
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::StripeError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the subscriptions page' do
          expect(response).to redirect_to(profile_subscription_path)
        end

      end

      context 'when invalid params are submitted' do

        it 'redirects to the plan page if there is a plan' do
          delete :destroy, :id => 'unknown'
          expect(response).to redirect_to(profile_subscription_path)
        end

      end

    end

  end

end
