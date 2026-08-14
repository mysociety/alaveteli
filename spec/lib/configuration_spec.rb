require 'spec_helper'

RSpec.describe AlaveteliConfiguration do
  include AlaveteliConfiguration

  describe '#to_sanitized_hash' do
    subject { described_class.to_sanitized_hash }
    it { is_expected.to include(:INCOMING_EMAIL_SECRET => '[FILTERED]') }

    context 'with a UserCheck API key configured' do
      before { ENV['ALAVETELI_USERCHECK_API_KEY'] = 'real-api-key' }
      after { ENV.delete('ALAVETELI_USERCHECK_API_KEY') }

      it { is_expected.to include(USERCHECK_API_KEY: '[FILTERED]') }
    end
  end
end
