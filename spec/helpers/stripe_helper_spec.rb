require 'spec_helper'

describe StripeHelper do
  include StripeHelper

  let(:current_user) { FactoryBot.create(:user) }

  before(:each) do
    allow(AlaveteliConfiguration).to receive(:stripe_publishable_key).
      and_return('ABC123')
    allow(AlaveteliConfiguration).to receive(:pro_site_name).
      and_return('Pro Site')
  end

  describe '#stripe_button' do

    it 'outputs javascript tag with remote Stripe.com source' do
      expect(stripe_button).to have_xpath(
        '//script[@src="https://checkout.stripe.com/checkout.js"]',
        class: 'stripe-button',
        visible: false
      )
    end

    it 'includes default data attibutes' do
      script = Nokogiri::HTML(stripe_button).xpath('//script')[0]
      expect(script['data-key']).to eq('ABC123')
      expect(script['data-name']).to eq('Pro Site')
      expect(script['data-allow-remember-me']).to eq('false')
      expect(script['data-email']).to eq(current_user.email)
      expect(script['data-image']).to match(/https.*\.png/)
      expect(script['data-locale']).to eq('auto')
      expect(script['data-zip-code']).to eq('true')
    end

    it 'can override default data attibutes' do
      button = stripe_button(name: 'Alaveteli Professional')
      script = Nokogiri::HTML(button).xpath('//script')[0]
      expect(script['data-name']).to eq('Alaveteli Professional')
    end

    it 'can add other data attibutes' do
      button = stripe_button(amount: 1000, currency: 'GBP')
      script = Nokogiri::HTML(button).xpath('//script')[0]
      expect(script['data-amount']).to eq('1000')
      expect(script['data-currency']).to eq('GBP')
    end

  end

end
