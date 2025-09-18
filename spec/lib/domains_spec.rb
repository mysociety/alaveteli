require 'spec_helper'

RSpec.describe Domains do
  describe '.webmail_providers' do
    subject { described_class.webmail_providers }

    context 'includes global defaults' do
      it { is_expected.to include('gmail.com') }
    end

    context 'allows custom additions' do
      around do |example|
        described_class.webmail_providers << 'example.com'
        example.run
        described_class.webmail_providers.delete('example.com')
      end

      it { is_expected.to include('example.com') }
    end

    context 'can be completely overridden' do
      around do |example|
        original = described_class.webmail_providers.dup
        described_class.webmail_providers = ['example.com']
        example.run
        described_class.webmail_providers = original
      end

      it { is_expected.to match_array(%w[example.com]) }
    end
  end
end
