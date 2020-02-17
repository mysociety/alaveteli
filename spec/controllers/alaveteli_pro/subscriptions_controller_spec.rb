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
    allow(AlaveteliConfiguration).
      to receive(:stripe_tax_rate).and_return('0.25')
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
          expect(assigns(:pro_account).stripe_customer.email).
            to eq(user.email)
        end

        it 'subscribes the user to the plan' do
          expect(assigns(:subscription).plan.id).to eq('pro')
          expect(assigns(:pro_account).stripe_customer_id).
            to eq(assigns(:subscription).customer)
        end

        it 'sets subscription plan amount and tax percentage' do
          expect(assigns(:subscription).plan.amount).to eq 1000
          expect(assigns(:subscription).tax_percent).to eql 25.0
        end

        it 'creates a pro account for the user' do
          expect(user.pro_account).to be_present
        end

        it 'stores the stripe_customer_id in the pro_account' do
          expect(user.pro_account.stripe_customer_id).
            to eq(assigns(:pro_account).stripe_customer_id)
        end

        it 'redirects to the authorise action' do
          expect(response).to redirect_to(
            authorise_subscription_path(assigns(:subscription).id)
          )
        end

      end

      # technically possible but have only managed to do so locally (and with
      # Safari) but just in case...
      context 'the form is resubmitted' do

        let(:token) { stripe_helper.generate_card_token }
        let(:user) { FactoryBot.create(:user) }

        before do
          session[:user_id] = user.id
          post :create, params: {
            'stripe_token' => token,
            'plan_id' => 'pro',
            'coupon_code' => ''
          }
          post :create, params: {
            'stripe_token' => token,
            'plan_id' => 'pro',
            'coupon_code' => ''
          }
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

      context 'with a successful transaction' do
        before do
          post :create, params: {
            'stripe_token' => token,
            'plan_id' => 'pro',
            'coupon_code' => ''
          }
        end

        include_examples 'successful example'
      end

      context 'with coupon code' do
        before do
          post :create, params: {
            'stripe_token' => token,
            'plan_id' => 'pro',
            'coupon_code' => 'coupon_code'
          }
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

          post :create, params: {
            'stripe_token' => token,
            'plan_id' => 'pro',
            'coupon_code' => 'coupon_code'
          }
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

          post :create, params: {
            'stripe_token' => token,
            'plan_id' => 'pro',
            'coupon_code' => ''
          }
        end

        include_examples 'successful example'

        it 'uses the existing stripe customer record' do
          customers = Stripe::Customer.list.map(&:id)
          expect(customers).to eq([user.pro_account.stripe_customer_id])
        end

        it 'updates the source from the new token' do
          expect(assigns[:pro_account].stripe_customer.default_source).
            to eq(assigns[:token].card.id)
        end
      end

      context 'with an existing customer and an incomplete subscription' do

        let(:customer) do
          Stripe::Customer.create(
            email: user.email,
            source: stripe_helper.generate_card_token
          )
        end

        let(:pro_account) do
          user.create_pro_account(stripe_customer_id: customer.id)
        end

        it 'should cancel any incomplete subscriptions' do
          # we can't create a subscription in the incomplete status so we have
          # to need a lot of stubs.
          subscription = Stripe::Subscription.create(
            customer: customer,
            plan: 'pro'
          )

          subs = double(:subscription_collection).as_null_object
          allow(controller).to receive(:current_user).and_return(user)
          allow(controller).to receive(:prevent_duplicate_submission)
          allow(pro_account).to receive(:subscriptions).and_return(subs)
          allow(subs).to receive(:incomplete).and_return([subscription])

          expect(subscription).to receive(:delete).once

          post :create, params: {
            'stripe_token' => token,
            'plan_id' => 'pro'
          }
        end
      end

      context 'when the card is declined' do

        before do
          StripeMock.prepare_card_error(:card_declined, :create_subscription)
          post :create, params: {
            'stripe_token' => token,
            'plan_id' => 'pro',
            'coupon_code' => ''
          }
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
          post :create, params: {
            'stripe_token' => token,
            'plan_id' => 'pro',
            'coupon_code' => ''
          }
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
          post :create, params: {
            'stripe_token' => token,
            'plan_id' => 'pro',
            'coupon_code' => ''
          }
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
          post :create, params: {
            'stripe_token' => token,
            'plan_id' => 'pro',
            'coupon_code' => ''
          }
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
          post :create, params: {
            'stripe_token' => token,
            'plan_id' => 'pro',
            'coupon_code' => ''
          }
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
          post :create, params: {
            'stripe_token' => token,
            'plan_id' => 'pro',
            'coupon_code' => ''
          }
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
          post :create, params: {
            'stripe_token' => token,
            'plan_id' => 'pro',
            'coupon_code' => 'INVALID'
          }
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
          post :create, params: {
            'stripe_token' => token,
            'plan_id' => 'pro',
            'coupon_code' => 'EXPIRED'
          }
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

  describe 'GET #authorise' do

    context 'without a signed-in user' do

      before do
        get :authorise, params: { id: 1 }
      end

      it 'redirects to the login form' do
        expect(response).
          to redirect_to(signin_path(token: PostRedirect.last.token))
      end

    end

    context 'with a signed-in user' do
      let(:token) { stripe_helper.generate_card_token }

      let(:customer) { Stripe::Customer.create(source: token, plan: 'pro') }
      let(:pro_account) do
        FactoryBot.create(:pro_account, stripe_customer_id: customer.id)
      end
      let(:user) { pro_account.user }

      before do
        session[:user_id] = user.id
        allow(controller).to receive(:current_user).and_return(user)
      end

      subject(:authorise) do
        get :authorise, params: { id: 1 }
      end

      shared_context 'JSON request' do
        subject(:authorise) do
          get :authorise, params: { id: 1, format: :json }
        end
      end

      shared_examples 'errored' do

        it 'renders an error message' do
          authorise
          expect(flash[:error]).to match(/There was a problem/)
        end

        it 'redirects to the plan page' do
          authorise
          expect(response).to redirect_to(plan_path('pro'))
        end

        context 'when responding to JSON' do

          include_context 'JSON request'

          it 'returns URL to the pro dashboard' do
            authorise
            expect(JSON.parse(response.body, symbolize_names: true)).to eq(
              url: plan_path('pro')
            )
          end

        end

      end

      context 'subscription not found' do

        before do
          allow(pro_account.subscriptions).to receive(:retrieve).with('1').
            and_return(nil)
        end

        it 'responds with a 404 not found error' do
          authorise
          expect(response.status).to eq 404
        end

      end

      context 'subscription require authorisation' do

        before do
          subscription = double(
            :subscription,
            id: 1,
            require_authorisation?: true,
            payment_intent: double(client_secret: 'ABC_123')
          )

          allow(pro_account.subscriptions).to receive(:retrieve).with('1').
            and_return(subscription)
        end

        it 'raises unknown format error' do
          expect { authorise }.to raise_error(ActionController::UnknownFormat)
        end

        context 'when responding to JSON' do

          include_context 'JSON request'

          it 'should render payment intent client secret' do
            authorise
            expect(JSON.parse(response.body, symbolize_names: true)).to eq(
              payment_intent: 'ABC_123',
              callback_url: authorise_subscription_path(1)
            )
          end

        end

      end

      context 'subscription invoice open' do

        before do
          subscription = double(
            :subscription,
            require_authorisation?: false,
            invoice_open?: true,
            plan: double(id: 'pro')
          )

          allow(pro_account.subscriptions).to receive(:retrieve).with('1').
            and_return(subscription)
        end

        include_examples 'errored'

      end

      context 'subscription active' do

        before do
          subscription = double(
            :subscription,
            require_authorisation?: false,
            invoice_open?: false,
            active?: true
          )

          allow(pro_account.subscriptions).to receive(:retrieve).with('1').
            and_return(subscription)
        end

        it 'adds the pro role' do
          authorise
          expect(user.is_pro?).to eq(true)
        end

        it 'welcomes the new user' do
          authorise
          partial_file = "alaveteli_pro/subscriptions/signup_message.html.erb"
          expect(flash[:notice]).to eq(partial: partial_file)
        end

        it 'sets new_pro_user in flash' do
          authorise
          expect(flash[:new_pro_user]).to be true
        end

        it 'redirects to the pro dashboard' do
          authorise
          expect(response).to redirect_to(alaveteli_pro_dashboard_path)
        end

        context 'when responding to JSON' do

          include_context 'JSON request'

          it 'returns URL to the pro dashboard' do
            authorise
            expect(JSON.parse(response.body, symbolize_names: true)).to eq(
              url: alaveteli_pro_dashboard_path
            )
          end

        end

      end

      context 'when we are rate limited' do

        before do
          error = Stripe::RateLimitError.new
          StripeMock.prepare_error(error, :retrieve_customer_subscription)
        end

        include_examples 'errored'

        it 'sends an exception email' do
          authorise
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::RateLimitError/)
        end

      end

      context 'when Stripe receives an invalid request' do

        before do
          error = Stripe::InvalidRequestError.new('message', 'param')
          StripeMock.prepare_error(error, :retrieve_customer_subscription)
        end

        include_examples 'errored'

        it 'sends an exception email' do
          authorise
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::InvalidRequestError/)
        end

      end

      context 'when we cannot authenticate with Stripe' do

        before do
          error = Stripe::AuthenticationError.new
          StripeMock.prepare_error(error, :retrieve_customer_subscription)
        end

        include_examples 'errored'

        it 'sends an exception email' do
          authorise
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::AuthenticationError/)
        end

      end

      context 'when we cannot connect to Stripe' do

        before do
          error = Stripe::APIConnectionError.new
          StripeMock.prepare_error(error, :retrieve_customer_subscription)
        end

        include_examples 'errored'

        it 'sends an exception email' do
          authorise
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::APIConnectionError/)
        end

      end

      context 'when Stripe returns a generic error' do

        before do
          error = Stripe::StripeError.new
          StripeMock.prepare_error(error, :retrieve_customer_subscription)
        end

        include_examples 'errored'

        it 'sends an exception email' do
          authorise
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::StripeError/)
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

      let(:user) do
        user = FactoryBot.create(:pro_user)
        user.pro_account.update(stripe_customer_id: nil)
        user
      end

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
        expect(response).to be_successful
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

      let(:user) do
        FactoryBot.create(:pro_user)
      end

      before do
        user.pro_account.update(stripe_customer_id: nil)
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
