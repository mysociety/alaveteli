require 'spec_helper'
require 'stripe_mock'

RSpec.describe AlaveteliPro::InvoiceCollection do
  let(:collection) { described_class.new(customer) }
  let(:customer) { double(:customer, id: 'cus_123') }

  let(:open_invoice) { double(:invoice, status: 'open') }
  let(:paid_invoice) { double(:invoice, status: 'paid', amount_paid: 10) }

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

  describe '#retrieve' do
    context 'without customer' do
      let(:customer) { nil }

      it 'returns nil' do
        expect(collection.retrieve(123)).to eq nil
      end
    end

    context 'with Stripe invoices' do
      let(:invoices) { Stripe::ListObject.new }

      before do
        allow(Stripe::Invoice).to receive(:list).with(customer: 'cus_123').
          and_return(invoices)
      end

      it 'should retrieve wrapped invoice' do
        invoice = double('Stripe::Invoice')
        allow(invoices).to receive(:retrieve).with(123).
          and_return(invoice)
        expect(collection.retrieve(123)).to be_a AlaveteliPro::Invoice
        expect(collection.retrieve(123)).to eq invoice
      end
    end
  end

  describe '#open' do
    before do
      allow(Stripe::Invoice).to receive(:list).with(customer: 'cus_123').
        and_return([open_invoice, paid_invoice])
    end

    it 'should return any open invoice' do
      expect(collection.open).to match_array([open_invoice])
    end
  end

  describe '#paid' do
    before do
      allow(Stripe::Invoice).to receive(:list).with(customer: 'cus_123').
        and_return([open_invoice, paid_invoice])
    end

    it 'should return any paid invoice' do
      expect(collection.paid).to match_array([paid_invoice])
    end
  end

  describe '#each' do
    context 'without customer' do
      let(:customer) { nil }

      it 'returns no invoices' do
        expect(collection.count).to eq 0
      end
    end

    context 'with Stripe invoices' do
      let(:invoices) { Stripe::ListObject.new }

      before do
        allow(Stripe::Invoice).to receive(:list).with(customer: 'cus_123').
          and_return(invoices)
        allow(invoices).to receive(:auto_paging_each).
          and_yield(open_invoice).
          and_yield(paid_invoice)
      end

      it 'returns to correct amount of objects' do
        expect(collection.count).to eq 2
      end

      it 'wraps invoices as AlaveteliPro::Invoice objects' do
        expect(collection.to_a).to all(be_a AlaveteliPro::Invoice)
      end
    end

    context 'without Stripe invoices' do
      before do
        allow(Stripe::Invoice).to receive(:list).with(customer: 'cus_123').
          and_return([open_invoice, paid_invoice, open_invoice])
      end

      it 'returns to correct amount of objects' do
        expect(collection.count).to eq 3
      end

      it 'wraps invoices as AlaveteliPro::Invoice objects' do
        expect(collection.to_a).to all(be_a AlaveteliPro::Invoice)
      end
    end

    context 'without block' do
      it 'should return a Enumerator' do
        expect(collection.each).to be_a Enumerator
      end
    end
  end
end
