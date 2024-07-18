require 'spec_helper'

RSpec.describe AlaveteliConfiguration do
  include AlaveteliConfiguration

  describe '#to_sanitized_hash' do
    subject { described_class.to_sanitized_hash }
    it { is_expected.to include(:INCOMING_EMAIL_SECRET => '[FILTERED]') }
  end
end
