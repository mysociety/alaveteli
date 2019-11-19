require 'spec_helper'

describe StripeHelper do

  describe '#stripe_locale' do

    class MockHelper
      include StripeHelper

      def initialize(locale)
        @locales = { current: locale }
      end
    end

    subject { MockHelper.new(locale).stripe_locale }

    context 'current local supported by Stripe' do

      let(:locale) { 'en' }
      it { is_expected.to eq 'en' }

    end

    context 'current local not supported by Stripe' do

      let(:locale) { 'cy' }
      it { is_expected.to eq 'auto' }

    end

  end

end
