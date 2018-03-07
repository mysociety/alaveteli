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

  before do
    StripeMock.start
  end

  after do
    StripeMock.stop
  end

  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:plan) { stripe_helper.create_plan(id: 'pro', amount: 1000) }

  let(:customer) do
    Stripe::Customer.create(
      email: FactoryGirl.build(:user).email,
      source: stripe_helper.generate_card_token
    )
  end

  let(:subscription) do
    Stripe::Subscription.create(customer: customer, plan: plan.id)
  end

  let(:backdated_pro_account) do
    time_travel_to('2017-02-15') do
      account = FactoryGirl.create(:pro_account)
      AlaveteliFeatures.backend.enable(:pro_batch_access, account.user)
      # rolify doesn't work with time_travel for some reason so cheating...
      account.user.roles(:pro).last.update_column(:created_at, Time.zone.now)
      account
    end
  end

  describe 'validations' do

    it 'requires a user' do
      pro_account = FactoryGirl.build(:pro_account, user: nil)
      expect(pro_account).not_to be_valid
    end

  end

  describe 'create callbacks' do

    it 'creates Stripe customer and stores Stripe customer ID' do
      pro_account = FactoryGirl.build(:pro_account, stripe_customer_id: nil)
      expect(Stripe::Customer).to receive(:create).and_call_original
      pro_account.run_callbacks :create
      expect(pro_account.stripe_customer_id).to_not be_nil
    end

    context 'with pro_pricing disabled' do

      it 'does not create a Stripe customer' do
        with_feature_disabled(:alaveteli_pro) do
          pro_account = FactoryGirl.build(:pro_account, stripe_customer_id: nil)
          pro_account.run_callbacks :create
          expect(pro_account.stripe_customer_id).to be_nil
        end
      end

    end

  end

  describe '#stripe_customer' do

    subject { pro_account.stripe_customer }

    context 'with invalid Stripe customer ID' do
      let(:pro_account) do
        FactoryGirl.create(:pro_account, stripe_customer_id: 'invalid_id')
      end

      it 'raises an error' do
        expect{ pro_account.stripe_customer }.
          to raise_error Stripe::InvalidRequestError
      end

    end

    context 'with valid Stripe customer ID' do
      let(:pro_account) do
        FactoryGirl.create(:pro_account, stripe_customer_id: customer.id)
      end

      it 'finds the Stripe::Customer linked to the ProAccount' do
        expect(pro_account.stripe_customer).to eq(customer)
      end

    end

  end

  describe '#active?' do
    let(:pro_account) do
      FactoryGirl.create(:pro_account, stripe_customer_id: customer.id)
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

  describe '#monthly_batch_limit' do
    let(:pro_account) { FactoryGirl.build(:pro_account) }
    subject { pro_account.monthly_batch_limit }

    context 'the monthly_batch_limit has not been set in the database' do

      it { is_expected.to eq 1 }

      it 'takes the default value from AlaveteliConfiguration' do
        allow(AlaveteliConfiguration).
          to receive(:pro_monthly_batch_limit).and_return(42)

        expect(subject).to eq 42
      end

    end

    context 'monthly_batch_limit has been set' do
      before { pro_account.monthly_batch_limit = 42 }
      it { is_expected.to eq 42 }
    end

  end

  describe '#batches_remaining' do

    let(:pro_account) do
      account = FactoryGirl.create(:pro_account)
      AlaveteliFeatures.backend.enable(:pro_batch_access, account.user)
      account
    end

    before { allow(pro_account).to receive(:monthly_batches).and_return(1) }

    it 'returns the monthly batch limit if no batches have been made' do
      expect(pro_account.batches_remaining).to eq 1
    end

    it 'returns 0 if all the available batches have been used' do
      FactoryGirl.create(:info_request_batch, user: pro_account.user)
      expect(pro_account.batches_remaining).to eq 0
    end

    it 'returns 0 if more than the available batches have been used' do
      FactoryGirl.create(:info_request_batch, user: pro_account.user)
      FactoryGirl.create(:info_request_batch, user: pro_account.user)
      expect(pro_account.batches_remaining).to eq 0
    end

    it 'returns 0 if the user does not have the pro_batch_access feature flag' do
      AlaveteliFeatures.backend.disable(:pro_batch_access, pro_account.user)
      expect(pro_account.batches_remaining).to eq 0
    end

  end

  describe '#became_pro' do

    subject { backdated_pro_account.became_pro }

    it 'returns the expected date' do
      expect(subject.to_date).to eq Date.parse('2017-02-15')
    end

  end

  describe '#batch_period_start' do

    subject { backdated_pro_account.batch_period_start }

    it 'returns the previous month if the account anniversary has passed' do
      time_travel_to('2018-02-14') do
        expect(subject).to eq Time.zone.parse('2018-01-15')
      end
    end

    it 'returns the current month if the anniversary has not yet hit' do
      time_travel_to('2018-02-16') do
        expect(subject).to eq Time.zone.parse('2018-02-15')
      end
    end

    it 'returns the current month if the current day and the anniversary match' do
      time_travel_to('2018-02-15') do
        expect(subject).to eq Time.zone.parse('2018-02-15')
      end
    end

    it 'returns the end of the current month rather than 31 Feb or 3 March' do
      allow(backdated_pro_account).
        to receive(:became_pro) { Time.zone.parse('2017-12-31') }

      time_travel_to('2018-03-02') do
        expect(subject).to eq Time.zone.parse('2018-02-28')
      end
    end

    it 'returns the correct day in the previous month if current month is short' do
      allow(backdated_pro_account).
        to receive(:became_pro) { Time.zone.parse('2017-12-31') }

      time_travel_to('2018-02-15') do
        expect(subject).to eq Time.zone.parse('2018-01-31')
      end
    end

  end

  describe '#batch_period_renews' do

    subject { backdated_pro_account.batch_period_renews }

    it 'returns the current month if the account anniversary has passed' do
      time_travel_to('2018-02-14') do
        expect(subject).to eq Time.zone.parse('2018-02-15')
      end
    end

    it 'returns the next month if the anniversary has not yet hit' do
      time_travel_to('2018-02-16') do
        expect(subject).to eq Time.zone.parse('2018-03-15')
      end
    end

    it 'returns the next month if the current day and the anniversary match' do
      time_travel_to('2018-02-15') do
        expect(subject).to eq Time.zone.parse('2018-03-15')
      end
    end

    it 'returns the end of the current month rather than 31 Feb or 3 March' do
      allow(backdated_pro_account).
        to receive(:became_pro) { Time.zone.parse('2017-12-31') }

      time_travel_to('2018-02-15') do
        expect(subject).to eq Time.zone.parse('2018-02-28')
      end
    end

  end

  describe '#update_email_address' do
    let(:user) { FactoryGirl.build(:user, email: 'bilbo@example.com') }
    let(:pro_account) { FactoryGirl.create(:pro_account, user: user) }

    before { allow(pro_account).to receive(:stripe_customer) { customer } }

    it 'update Stripe customer email address' do
      expect(customer.email).to_not eq user.email
      expect(customer).to receive(:save)
      pro_account.update_email_address
      expect(customer.email).to eq user.email
    end

  end

end
