require 'spec_helper'

RSpec.describe AlaveteliPro::Subscription do

  let(:object) { Stripe::Subscription.new }
  let(:subscription) { described_class.new(object) }

  describe '#active?' do

    it 'should return true if status is active' do
      object.status = 'active'
      expect(subscription.active?).to eq true
    end

    it 'should return false if status is not active' do
      object.status = 'other'
      expect(subscription.active?).to eq false
    end

  end

  describe '#past_due?' do

    it 'should return true if status is past_due' do
      object.status = 'past_due'
      expect(subscription.past_due?).to eq true
    end

    it 'should return false if status is not past_due' do
      object.status = 'other'
      expect(subscription.past_due?).to eq false
    end

  end

  describe '#incomplete?' do

    it 'should return true if status is incomplete' do
      object.status = 'incomplete'
      expect(subscription.incomplete?).to eq true
    end

    it 'should return false if status is not incomplete' do
      object.status = 'other'
      expect(subscription.incomplete?).to eq false
    end

  end

  describe '#latest_invoice' do

    subject { subscription.latest_invoice }

    it 'should retrieve and return a Stripe Invoice object' do
      object.latest_invoice = 'invoice_123'
      mock_invoice = double('Stripe::Invoice')
      allow(Stripe::Invoice).to receive(:retrieve).with('invoice_123').
        and_return(mock_invoice)
      is_expected.to eq mock_invoice
    end

  end

  describe '#invoice_open?' do

    subject { subscription.invoice_open? }

    context 'when subscription complete' do

      before do
        allow(subscription).to receive(:incomplete?).and_return(false)
      end

      it { is_expected.to eq false }

    end

    context 'when subscription incomplete' do

      before do
        allow(subscription).to receive(:incomplete?).and_return(true)
      end

      it 'return true when latest invoice status is open' do
        allow(subscription).to receive(:latest_invoice).and_return(
          double('Stripe::Invoice', status: 'open')
        )
        is_expected.to eq true
      end

      it 'return false when latest invoice status is closed' do
        allow(subscription).to receive(:latest_invoice).and_return(
          double('Stripe::Invoice', status: 'closed')
        )
        is_expected.to eq false
      end

    end

  end

  describe '#payment_intent' do

    subject { subscription.payment_intent }

    before do
      allow(subscription).to receive(:latest_invoice).and_return(invoice)
    end

    context 'with latest_invoice' do

      let(:invoice) { double('Stripe::Invoice', payment_intent: 'pi_123') }

      it 'should retrieve and return a Stripe Payment Intent object' do
        mock_payment_intent = double('Stripe::PaymentIntent')
        allow(Stripe::PaymentIntent).to receive(:retrieve).with('pi_123').
          and_return(mock_payment_intent)
        expect(subscription.payment_intent).to eq mock_payment_intent
      end

    end

    context 'without latest_invoice' do

      let(:invoice) { nil }
      it { is_expected.to eq nil }

    end

  end

  describe '#require_authorisation?' do

    subject { subscription.require_authorisation? }

    context 'when invoice open' do

      before do
        allow(subscription).to receive(:invoice_open?).and_return(true)
      end

      it 'return true if payment intent status is requires_source_action' do
        allow(subscription).to receive(:payment_intent).and_return(
          double('Stripe::PaymentIntent', status: 'requires_source_action')
        )
        is_expected.to eq true
      end

      it 'return true if payment intent status is require_action' do
        allow(subscription).to receive(:payment_intent).and_return(
          double('Stripe::PaymentIntent', status: 'require_action')
        )
        is_expected.to eq true
      end

      it 'return false for any other payment intent status' do
        allow(subscription).to receive(:payment_intent).and_return(
          double('Stripe::PaymentIntent', status: 'other')
        )
        is_expected.to eq false
      end

    end

    context 'when invoice closed' do

      before do
        allow(subscription).to receive(:invoice_open?).and_return(false)
      end

      it { is_expected.to eq false }

    end

  end

  describe 'missing methods' do

    it 'should delegate methods to object' do
      mock_coupon = double(:coupon)
      expect { subscription.coupon }.to raise_error(NoMethodError)
      expect { subscription.coupon = mock_coupon }.to_not raise_error
      expect(subscription.coupon).to eq mock_coupon
      expect(subscription.__getobj__.coupon).to eq mock_coupon
    end

  end

end
