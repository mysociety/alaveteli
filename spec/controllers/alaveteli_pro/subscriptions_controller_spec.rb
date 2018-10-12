# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'stripe_mock'

describe AlaveteliPro::SubscriptionsController, feature: :pro_pricing do
  let(:stripe_helper) { StripeMock.create_test_helper }

  before do
    StripeMock.start
    stripe_helper.create_plan(id: 'pro', amount: 1000)
    stripe_helper.create_coupon(
      id: 'COUPON_CODE',
      amount_off: 1000,
      currency: 'gbp'
    )
    stripe_helper.create_coupon(
      id: 'ALAVETELI-COUPON_CODE',
      amount_off: 1000,
      currency: 'gbp'
    )
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
      let(:token) { stripe_helper.generate_card_token }
      let(:user) { FactoryBot.create(:user) }

      before do
        session[:user_id] = user.id
      end

      RSpec.shared_examples 'successful example' do
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

        it 'adds the pro role' do
          expect(user.is_pro?).to eq(true)
        end

        it 'does not enable pop polling by default' do
          result =
            AlaveteliFeatures.backend[:accept_mail_from_poller].enabled?(user)
          expect(result).to eq(false)
        end

        it 'enables daily summary notifications for the user' do
          result =
            AlaveteliFeatures.backend[:notifications].enabled?(user)
          expect(result).to eq(true)
        end

        it 'enables batch for the user' do
          result =
            AlaveteliFeatures.backend[:pro_batch_access].enabled?(user)
          expect(result).to eq(true)
        end

        it 'welcomes the new user' do
          partial_file = "alaveteli_pro/subscriptions/signup_message.html.erb"
          expect(flash[:notice]).to eq({ :partial => partial_file })
        end

        it 'redirects to the pro dashboard' do
          expect(response).to redirect_to(alaveteli_pro_dashboard_path)
        end

        it 'sets new_pro_user in flash' do
          expect(flash[:new_pro_user]).to be true
        end

      end

      # technically possible but have only managed to do so locally (and with
      # Safari) but just in case...
      context 'the form is resubmitted' do

        let(:token) { stripe_helper.generate_card_token }
        let(:user) { FactoryBot.create(:user) }

        before do
          session[:user_id] = user.id
          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => '' }
          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => '' }
        end

        it 'does not create a duplicate subscription' do
          user.reload
          expect(user.pro_account.stripe_customer.subscriptions.count).
            to eq 1
        end

        it 'redirects to the dashboard' do
          expect(response).to redirect_to(alaveteli_pro_dashboard_path)
        end

      end

      context 'the user previously had some pro features enabled' do

        def successful_signup
          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => 'coupon_code' }
        end

        it 'does not raise an error if the user already uses the poller' do
          AlaveteliFeatures.backend.enable_actor(:accept_mail_from_poller, user)
          expect { successful_signup }.not_to raise_error
        end

        it 'does not raise an error if the user already has notifications' do
          AlaveteliFeatures.backend.enable_actor(:notifications, user)
          expect { successful_signup }.not_to raise_error
        end

        it 'does not raise an error if the user already has batch' do
          AlaveteliFeatures.backend.enable_actor(:pro_batch_access, user)
          expect { successful_signup }.not_to raise_error
        end

      end

      context 'with a successful transaction' do
        before do
          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => '' }
        end

        include_examples 'successful example'
      end

      context 'when pop polling is enabled' do

        before do
          allow(AlaveteliConfiguration).
            to receive(:production_mailer_retriever_method).
            and_return('pop')

          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => '' }
        end

        it 'enables pop polling for the user' do
          result =
            AlaveteliFeatures.backend[:accept_mail_from_poller].enabled?(user)
          expect(result).to eq(true)
        end

      end

      context 'with coupon code' do
        before do
          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => 'coupon_code' }
        end

        include_examples 'successful example'

        it 'uses coupon code' do
          expect(assigns(:subscription).discount.coupon.id).to eq('COUPON_CODE')
        end
      end

      context 'with Stripe namespace and coupon code' do
        before do
          allow(AlaveteliConfiguration).to receive(:stripe_namespace).
            and_return('alaveteli')

          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => 'coupon_code' }
        end

        include_examples 'successful example'

        it 'uses namespaced coupon code' do
          expect(assigns(:subscription).discount.coupon.id).to eq(
            'ALAVETELI-COUPON_CODE')
        end
      end

      context 'with an existing customer but no active subscriptions' do

        before do
          customer =
            Stripe::Customer.create(email: user.email,
                                    source: stripe_helper.generate_card_token)
          user.create_pro_account(:stripe_customer_id => customer.id)

          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => '' }
        end

        include_examples 'successful example'

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

        before do
          StripeMock.prepare_card_error(:card_declined, :create_subscription)
          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => '' }
        end

        it 'renders the card error message' do
          expect(flash[:error]).to eq('The card was declined')
        end

        it 'redirects to the plan page' do
          expect(response).to redirect_to(plan_path('pro'))
        end

        it 'does not set new_pro_user in flash' do
          expect(flash[:new_pro_user]).to be_nil
        end

      end

      context 'when we are rate limited' do

        before do
          error = Stripe::RateLimitError.new
          StripeMock.prepare_error(error, :create_subscription)
          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => '' }
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

        before do
          error = Stripe::InvalidRequestError.new('message', 'param')
          StripeMock.prepare_error(error, :create_subscription)
          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => '' }
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

        before do
          error = Stripe::AuthenticationError.new
          StripeMock.prepare_error(error, :create_subscription)
          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => '' }
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

        before do
          error = Stripe::APIConnectionError.new
          StripeMock.prepare_error(error, :create_subscription)
          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => '' }
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

        before do
          error = Stripe::StripeError.new
          StripeMock.prepare_error(error, :create_subscription)
          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => '' }
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

      context 'when uses invalid coupon' do

        before do
          error = Stripe::InvalidRequestError.new('No such coupon', 'param')
          StripeMock.prepare_error(error, :create_subscription)
          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => 'INVALID' }
        end

        it 'does not sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail).to be_nil
        end

        it 'renders an notice message' do
          expect(flash[:error]).to eq('Coupon code is invalid.')
        end

        it 'redirects to the plan page' do
          expect(response).to redirect_to(plan_path('pro'))
        end

      end

      context 'when uses expired coupon' do

        before do
          error = Stripe::InvalidRequestError.new('Coupon expired', 'param')
          StripeMock.prepare_error(error, :create_subscription)
          post :create, params: { 'stripeToken' => token, 'stripeTokenType' => 'card', 'stripeEmail' => user.email, 'plan_id' => 'pro', 'coupon_code' => 'EXPIRED' }
        end

        it 'does not sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail).to be_nil
        end

        it 'renders an notice message' do
          expect(flash[:error]).to eq('Coupon code has expired.')
        end

        it 'redirects to the plan page' do
          expect(response).to redirect_to(plan_path('pro'))
        end

      end

      context 'when invalid params are submitted' do

        it 'redirects to the plan page if there is a plan' do
          post :create, params: { :plan_id => 'pro' }
          expect(response).to redirect_to(plan_path('pro'))
        end

        it 'redirects to the pricing page if there is no plan' do
          post :create
          expect(response).to redirect_to(pro_plans_path)
        end

      end

    end

  end

  describe 'GET #index' do

    context 'without a signed-in user' do

      before do
        get :index
      end

      it 'redirects to the login form' do
        expect(response).
          to redirect_to(signin_path(:token => PostRedirect.last.token))
      end

    end

    context 'user has no Stripe id' do

      let(:user) { FactoryBot.create(:pro_user) }

      before do
        session[:user_id] = user.id
      end

      it 'redirects to the pricing page' do
        get :index
        expect(response).to redirect_to(pro_plans_path)
      end

    end

    context 'with a signed-in user' do

      let(:user) { FactoryBot.create(:pro_user) }

      let!(:customer) do
        stripe_helper.create_plan(id: 'test')
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
      end

      it 'successfully loads the page' do
        get :index
        expect(response).to be_success
      end

      it 'finds the Stripe subscription for the user' do
        get :index
        expect(assigns[:customer].id).
          to eq(user.pro_account.stripe_customer_id)
      end

      it 'assigns subscriptions' do
        get :index
        expect(assigns[:subscriptions].length).to eq(1)
        expect(assigns[:subscriptions].first.id).
          to eq(customer.subscriptions.first.id)
      end

      it 'assigns the default source as card' do
        get :index
        expect(assigns[:card].id).to eq(customer.default_source)
      end

      context 'if a PRO_REFERRAL_COUPON is blank' do

        it 'does not assign the discount code' do
          get :index
          expect(assigns[:discount_code]).to be_nil
        end

        it 'does not assign the discount terms' do
          get :index
          expect(assigns[:discount_terms]).to be_nil
        end

      end

      context 'if a PRO_REFERRAL_COUPON is set' do

        before do
          allow(AlaveteliConfiguration).
            to receive(:pro_referral_coupon).and_return('PROREFERRAL')
          allow(AlaveteliConfiguration).
            to receive(:stripe_namespace).and_return('ALAVETELI')
        end

        let!(:coupon) do
          stripe_helper.create_coupon(
            percent_off: 50,
            duration: 'repeating',
            duration_in_months: 1,
            id: 'ALAVETELI-PROREFERRAL',
            metadata: { humanized_terms: '50% off for 1 month' }
          )
        end

        it 'assigns the discount code, stripping the stripe namespace' do
          get :index
          expect(assigns[:discount_code]).to eq('PROREFERRAL')
        end

        it 'assigns the discount terms' do
          get :index
          expect(assigns[:discount_terms]).to eq('50% off for 1 month')
        end

        it 'rescues from any stripe error' do
          error = Stripe::InvalidRequestError.new('Coupon expired', 'param')
          StripeMock.prepare_error(error, :get_coupon)
          get :index
          expect(assigns[:discount_code]).to be_nil
        end

      end

    end

  end

  describe 'DELETE #destroy' do

    context 'without a signed-in user' do

      before do
        delete :destroy, params: { id: '123' }
      end

      it 'redirects to the login form' do
        expect(response).
          to redirect_to(signin_path(:token => PostRedirect.last.token))
      end

    end

    context 'user has no Stripe id' do

      let(:user) { FactoryBot.create(:pro_user) }

      before do
        session[:user_id] = user.id
      end

      it 'raise an error' do
        expect {
          delete :destroy, params: { id: '123' }
        }.to raise_error ActiveRecord::RecordNotFound
      end

    end

    context 'with a signed-in user' do

      let(:user) { FactoryBot.create(:pro_user) }

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
        delete :destroy, params: { id: subscription.id }
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
        expect(response).to redirect_to(subscriptions_path)
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
          expect {
            delete :destroy, params: { id: other_subscription.id }
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'when we are rate limited' do

        before do
          error = Stripe::RateLimitError.new
          StripeMock.prepare_error(error, :cancel_subscription)
          delete :destroy, params: { id: subscription.id }
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::RateLimitError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the subscriptions page' do
          expect(response).to redirect_to(subscriptions_path)
        end

      end

      context 'when Stripe receives an invalid request' do

        before do
          error = Stripe::InvalidRequestError.new('message', 'param')
          StripeMock.prepare_error(error, :cancel_subscription)
          delete :destroy, params: { id: subscription.id }
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::InvalidRequestError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the subscriptions page' do
          expect(response).to redirect_to(subscriptions_path)
        end

      end

      context 'when we cannot authenticate with Stripe' do

        before do
          error = Stripe::AuthenticationError.new
          StripeMock.prepare_error(error, :cancel_subscription)
          delete :destroy, params: { id: subscription.id }
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::AuthenticationError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the subscriptions page' do
          expect(response).to redirect_to(subscriptions_path)
        end

      end

      context 'when we cannot connect to Stripe' do

        before do
          error = Stripe::APIConnectionError.new
          StripeMock.prepare_error(error, :cancel_subscription)
          delete :destroy, params: { id: subscription.id }
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::APIConnectionError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the subscriptions page' do
          expect(response).to redirect_to(subscriptions_path)
        end

      end

      context 'when Stripe returns a generic error' do

        before do
          error = Stripe::StripeError.new
          StripeMock.prepare_error(error, :cancel_subscription)
          delete :destroy, params: { id: subscription.id }
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::StripeError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the subscriptions page' do
          expect(response).to redirect_to(subscriptions_path)
        end

      end

      context 'when invalid params are submitted' do

        it 'redirects to the plan page if there is a plan' do
          delete :destroy, params: { :id => 'unknown' }
          expect(response).to redirect_to(subscriptions_path)
        end

      end

    end

  end

end
