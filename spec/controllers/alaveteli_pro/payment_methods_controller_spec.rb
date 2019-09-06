# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'stripe_mock'

describe AlaveteliPro::PaymentMethodsController, feature: :pro_pricing do
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:user_token) { stripe_helper.generate_card_token }
  let(:new_token) { stripe_helper.generate_card_token }

  before do
    StripeMock.start
    stripe_helper.create_plan(id: 'pro', amount: 1000)
  end

  after do
    StripeMock.stop
  end

  describe 'POST #update' do

    context 'without a signed-in user' do

      before do
        post :update
      end

      it 'redirects to the login form' do
        expect(response).
          to redirect_to(signin_path(:token => PostRedirect.last.token))
      end

    end

    context 'with a signed-in user' do
      let(:user) { FactoryBot.create(:pro_user) }

      let(:customer) do
        customer = Stripe::Customer.
                     create(email: user.email, source: user_token)
        user.pro_account.update!(stripe_customer_id: customer.id)
        customer
      end

      let!(:card_ids) { customer.sources.data.map(&:id) }

      before do
        session[:user_id] = user.id
      end

      it 'finds the card token' do
        post :update, params: { 'stripeToken' => new_token }
        expect(assigns(:token).id).to eq(new_token)
      end

      it 'retrieves the correct pro account' do
        post :update, params: { 'stripeToken' => new_token }
        expect(assigns(:pro_account).stripe_customer_id).
          to eq(user.pro_account.stripe_customer_id)
      end

      it 'redirects to the account page' do
        post :update, params: { 'stripeToken' => new_token }
        expect(response).to redirect_to(subscriptions_path)
      end

      context 'with a successful transaction' do

        before do
          post :update, params: { 'stripeToken' => new_token }
        end

        it 'adds the new card to the Stripe customer' do
          reloaded = Stripe::Customer.
                       retrieve(user.pro_account.stripe_customer_id)
          expect(reloaded.sources.data.map(&:id)).
            to include(assigns(:token).card.id)
        end

        it 'sets the new card as the default' do
          reloaded = Stripe::Customer.
                       retrieve(user.pro_account.stripe_customer_id)
          expect(reloaded.default_source).to eq(assigns(:token).card.id)
        end

        it 'removes the old card from the Stripe customer' do
          reloaded = Stripe::Customer.
                       retrieve(user.pro_account.stripe_customer_id)
          expect(reloaded.sources.data.map(&:id)).to_not match_array(card_ids)
        end

        it 'shows a message to confirm the update' do
          expect(flash[:notice]).to eq('Your payment details have been updated')
        end

      end

      context 'when the card is declined' do

        before do
          StripeMock.prepare_card_error(:card_declined, :update_customer)

          post :update, params: { 'stripeToken' => new_token }
        end

        it 'renders the card error message' do
          expect(flash[:error]).to eq('The card was declined')
        end

        it 'does not update the stored payment methods' do
          reloaded = Stripe::Customer.
                       retrieve(user.pro_account.stripe_customer_id)
          expect(reloaded.sources.data.map(&:id)).to match_array(card_ids)
        end

      end

      context 'when we are rate limited' do

        before do
          error = Stripe::RateLimitError.new
          StripeMock.prepare_error(error, :update_customer)
          post :update, params: { 'stripeToken' => new_token }
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::RateLimitError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

      end

      context 'when Stripe receives an invalid request' do

        before do
          error = Stripe::InvalidRequestError.new('message', 'param')
          StripeMock.prepare_error(error, :update_customer)
          post :update, params: { 'stripeToken' => new_token }
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::InvalidRequestError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

      end

      context 'when we cannot authenticate with Stripe' do

        before do
          error = Stripe::AuthenticationError.new
          StripeMock.prepare_error(error, :update_customer)
          post :update, params: { 'stripeToken' => new_token }
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::AuthenticationError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

      end

      context 'when we cannot connect to Stripe' do

        before do
          error = Stripe::APIConnectionError.new
          StripeMock.prepare_error(error, :update_customer)
          post :update, params: { 'stripeToken' => new_token }
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::APIConnectionError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

      end

      context 'when Stripe returns a generic error' do

        before do
          error = Stripe::StripeError.new
          StripeMock.prepare_error(error, :update_customer)
          post :update, params: { 'stripeToken' => new_token }
        end

        it 'sends an exception email' do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject).to match(/Stripe::StripeError/)
        end

        it 'renders an error message' do
          expect(flash[:error]).to match(/There was a problem/)
        end

      end

    end

  end

end
