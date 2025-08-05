require 'spec_helper'

RSpec.describe AlaveteliPro::SubscriptionCollection do

  let(:collection) { described_class.new(customer) }
  let(:customer) { double(:customer) }

  let(:active_subscription) { double(:subscription, status: 'active') }
  let(:past_due_subscription) { double(:subscription, status: 'past_due') }
  let(:incomplete_subscription) { double(:subscription, status: 'incomplete') }

  describe '.for_customer' do

    it 'should return instance for customer' do
      collection = described_class.for_customer(customer)
      expect(collection).to be_a described_class
    end

    it 'should pass customer to instance' do
      expect(described_class).to receive(:new).with(customer)
      described_class.for_customer(customer)
    end

  end

  describe '.new' do

    it 'should store customer instance variable' do
      expect(collection.instance_variable_get(:@customer)).to eq customer
    end

  end

  describe '#build' do

    let(:collection) { described_class.new(customer) }
    let(:subscription) { collection.build }

    it 'should build new subscription' do
      expect(subscription).to be_a AlaveteliPro::Subscription
    end

    it 'should delegated to a Stripe subscription' do
      expect(subscription.__getobj__).to be_a Stripe::Subscription
    end

    it 'should set customer object' do
      expect(subscription.customer).to eq customer
    end

  end

  describe '#retrieve' do

    context 'without customer' do

      let(:customer) { nil }

      it 'returns nil' do
        expect(collection.retrieve(123)).to eq nil
      end

    end

    context 'with Stripe subscriptions' do

      let(:subscriptions) do
        Stripe::ListObject.new
      end

      before do
        allow(customer).to receive(:subscriptions).and_return(subscriptions)
      end

      it 'should retrieve wrapped subscription' do
        subscription = double('Stripe::Subscription')
        allow(subscriptions).to receive(:retrieve).with(123).
          and_return(subscription)
        expect(collection.retrieve(123)).to be_a AlaveteliPro::Subscription
        expect(collection.retrieve(123)).to eq subscription
      end

    end

  end

  describe '#current' do

    before do
      allow(customer).to receive(:subscriptions).and_return(
        [active_subscription, past_due_subscription, incomplete_subscription]
      )
    end

    it 'should return any current subscription' do
      expect(collection.current).to match_array [
        active_subscription, past_due_subscription
      ]
    end

  end

  describe '#incomplete' do

    before do
      allow(customer).to receive(:subscriptions).and_return(
        [active_subscription, past_due_subscription, incomplete_subscription]
      )
    end

    it 'should return any incomplete subscription' do
      expect(collection.incomplete).to match_array [incomplete_subscription]
    end

  end

  describe '#each' do

    context 'without customer' do

      let(:customer) { nil }

      it 'returns no subscriptions' do
        expect(collection.count).to eq 0
      end

    end

    context 'with Stripe subscriptions' do

      let(:subscriptions) do
        Stripe::ListObject.new
      end

      before do
        allow(customer).to receive(:subscriptions).and_return(subscriptions)
        allow(subscriptions).to receive(:auto_paging_each).
          and_yield(active_subscription).
          and_yield(incomplete_subscription)
      end

      it 'returns to correct amount of objects' do
        expect(collection.count).to eq 2
      end

      it 'wraps subscriptions as AlaveteliPro::Subscription objects' do
        expect(collection.to_a).to all(be_a AlaveteliPro::Subscription)
      end

    end

    context 'without Stripe subscriptions' do

      before do
        allow(customer).to receive(:subscriptions).and_return(
          [active_subscription, incomplete_subscription, active_subscription]
        )
      end

      it 'returns to correct amount of objects' do
        expect(collection.count).to eq 3
      end

      it 'wraps subscriptions as AlaveteliPro::Subscription objects' do
        expect(collection.to_a).to all(be_a AlaveteliPro::Subscription)
      end

    end

    context 'without block' do

      it 'should return a Enumerator' do
        expect(collection.each).to be_a Enumerator
      end

    end

  end

end
