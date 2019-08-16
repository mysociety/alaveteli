# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: pro_accounts
#
#  id                       :integer          not null, primary key
#  user_id                  :integer          not null
#  default_embargo_duration :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  stripe_customer_id       :string
#

require 'spec_helper'
require 'stripe_mock'

describe ProAccount, feature: :pro_pricing do

  around { |example| StripeMock.mock(&example) }

  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:plan) { stripe_helper.create_plan(id: 'pro', amount: 1000) }

  let(:customer) do
    Stripe::Customer.create(source: stripe_helper.generate_card_token)
  end

  let(:subscription) do
    Stripe::Subscription.create(customer: customer, plan: plan.id)
  end

  describe 'validations' do

    let(:user) { FactoryBot.build(:pro_user) }
    subject(:pro_account) { FactoryBot.build(:pro_account, user: user) }

    it { is_expected.to be_valid }

    it 'requires a user' do
      pro_account.user = nil
      expect(pro_account).not_to be_valid
    end

  end

  describe '#update_stripe_customer', feature: :pro_pricing do

    let(:user) { FactoryBot.build(:pro_user) }
    let(:pro_account) { FactoryBot.build(:pro_account, user: user) }

    before do
      allow(Stripe::Customer).to receive(:new).and_return(customer)
    end

    it 'stores Stripe customer ID' do
      expect {
        pro_account.update_stripe_customer
      }.to change(pro_account, :stripe_customer_id).from(nil)
    end

    it 'creates Stripe customer' do
      allow(customer).to receive(:save)
      pro_account.update_stripe_customer
      expect(customer).to have_received(:save)
    end

    it 'sets Stripe customer email' do
      pro_account.update_stripe_customer
      expect(customer.email).to eq user.email
    end

    it 'sets Stripe customer default source' do
      old_source = customer.default_source
      pro_account.source = stripe_helper.generate_card_token

      expect { pro_account.update_stripe_customer }.to change(
        customer, :default_source
      ).from(old_source)
    end

    context 'with pro_pricing disabled' do

      it 'does not store Stripe customer ID' do
        with_feature_disabled(:pro_pricing) do
          expect {
            pro_account.update_stripe_customer
          }.to_not change(pro_account, :stripe_customer_id)
        end
      end

      it 'does not create a Stripe customer' do
        with_feature_disabled(:pro_pricing) do
          allow(customer).to receive(:save)
          pro_account.update_stripe_customer
          expect(customer).to_not have_received(:save)
          expect(pro_account.stripe_customer_id).to be_nil
        end
      end

      it 'does not set Stripe customer email' do
        with_feature_disabled(:pro_pricing) do
          allow(customer).to receive(:email=)
          pro_account.update_stripe_customer
          expect(customer).to_not have_received(:email=)
        end
      end

      it 'does not set new Stripe customer default source' do
        with_feature_disabled(:alaveteli_pro) do
          pro_account.source = stripe_helper.generate_card_token
          expect { pro_account.update_stripe_customer }.to_not change(
            customer, :default_source
          )
        end
      end

    end

  end

  describe '#stripe_customer' do

    subject { pro_account.stripe_customer }

    context 'with invalid Stripe customer ID' do
      let(:pro_account) do
        FactoryBot.build(:pro_account, stripe_customer_id: 'invalid_id')
      end

      it 'raises an error' do
        expect { pro_account.stripe_customer }.
          to raise_error Stripe::InvalidRequestError
      end

    end

    context 'with valid Stripe customer ID' do
      let(:pro_account) do
        FactoryBot.build(:pro_account, stripe_customer_id: customer.id)
      end

      it 'finds the Stripe::Customer linked to the ProAccount' do
        expect(pro_account.stripe_customer).to eq(customer)
      end

    end

  end

  describe '#active?' do
    let(:pro_account) do
      FactoryBot.create(:pro_account, stripe_customer_id: customer.id)
    end

    subject { pro_account.active? }

    context 'when there is an active subscription' do
      before { subscription.save }
      it { is_expected.to eq true }
    end

    context 'when there is an expiring subscription' do
      before { subscription.delete(at_period_end: true) }
      it { is_expected.to eq true }
    end

    context 'when an existing subscription is cancelled' do
      before { subscription.delete }
      it { is_expected.to eq false }
    end

    context 'when there are no active subscriptions' do
      it { is_expected.to eq false }
    end

    context 'when there is no customer id' do
      before { pro_account.stripe_customer_id = nil }
      it { is_expected.to eq false }
    end

  end

end
