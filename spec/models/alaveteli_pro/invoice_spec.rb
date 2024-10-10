require 'spec_helper'
require 'stripe_mock'

RSpec.describe AlaveteliPro::Invoice, type: :model do
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:invoice) { AlaveteliPro::Invoice.new(stripe_invoice) }

  let(:stripe_invoice) do
    Stripe::Invoice.create(
      id: 'in_123',
      status: 'open',
      charge: 'ch_123',
      created: 1722211200,
      amount_paid: 0
    )
  end

  let(:stripe_charge) { Stripe::Charge.new(id: 'ch_123') }

  before do
    allow(Stripe::Charge).
      to receive(:retrieve).with('ch_123').and_return(stripe_charge)
  end

  describe '#open?' do
    it 'returns true when the status is open' do
      expect(invoice).to be_open
    end

    it 'returns false when the status is not open' do
      allow(stripe_invoice).to receive(:status).and_return('paid')
      expect(invoice).not_to be_open
    end
  end

  describe '#paid?' do
    it 'returns true when the status is paid and an amount has been paid' do
      allow(stripe_invoice).to receive(:status).and_return('paid')
      allow(stripe_invoice).to receive(:amount_paid).and_return(1000)
      expect(invoice).to be_paid
    end

    it 'returns false when 100% discounted' do
      allow(stripe_invoice).to receive(:status).and_return('paid')
      expect(invoice).not_to be_paid
    end

    it 'returns false when the status is not paid' do
      allow(stripe_invoice).to receive(:amount_paid).and_return(1000)
      expect(invoice).not_to be_paid
    end
  end

  describe '#created' do
    it 'returns a date object for the invoice' do
      with_env_tz 'UTC' do
        expect(invoice.created).to eq(Date.new(2024, 7, 29))
      end
    end
  end

  describe '#charge' do
    it 'returns a Stripe::Charge object' do
      expect(invoice.charge).to eq(stripe_charge)
    end

    it 'memoizes the Stripe::Charge object' do
      expect(Stripe::Charge).to receive(:retrieve).once.with('ch_123')
      2.times { invoice.charge }
    end
  end

  describe '#receipt_url' do
    before do
      allow(stripe_charge).to receive(:receipt_url).and_return(
        'http://example.com/receipt'
      )
    end

    it 'delegates receipt_url to the charge' do
      expect(invoice.receipt_url).to eq('http://example.com/receipt')
    end

    it 'returns nil when there is no charge' do
      allow(stripe_invoice).to receive(:charge).and_return(nil)
      expect(invoice.receipt_url).to be_nil
    end
  end

  describe '#method_missing' do
    it 'forwards missing methods to the original object' do
      allow(stripe_invoice).
        to receive(:some_missing_method).and_return('result')
      expect(invoice.some_missing_method).to eq('result')
    end
  end
end
