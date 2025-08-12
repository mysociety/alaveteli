require 'spec_helper'

RSpec.describe 'alaveteli_pro/plans/index.html.erb' do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:product) { stripe_helper.create_product }

  let(:plan_with_tax) { AlaveteliPro::WithTax.new(stripe_plan) }
  let(:cents_price) { 880 }

  let(:stripe_plan) do
    stripe_helper.create_plan(
      id: 'pro', product: product.id, amount: cents_price
    )
  end

  before do
    allow(AlaveteliConfiguration).to receive(:iso_currency_code).
        and_return('GBP')
    assign :plan, plan_with_tax
    assign :pro_site_name, 'Alaveteli<sup>Pro</sup>'
  end

  it 'uses the pro site name assigned by the controller' do
    render
    expect(rendered).
      to have_css('h2', text: assigns[:pro_site_name])
  end

  context 'the price does not have a cents value' do
    it 'shows the price without trailing cents' do
      render
      expect(rendered).
        to have_css('span', class: 'price-label__amount', text: '£10')
    end
  end

  context 'the price has a cents value' do
    let(:cents_price) { 832 }

    it 'shows the whole amount including cents' do
      render
      expect(rendered).
        to have_css('span', class: 'price-label__amount', text: '£9.98')
    end
  end
end
