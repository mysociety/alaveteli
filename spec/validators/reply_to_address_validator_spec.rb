require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ReplyToAddressValidator do

  describe '.no_reply_regexp' do
    subject { described_class.no_reply_regexp }

    context 'when a custom value has not been set' do
      it { is_expected.to eq(described_class::DEFAULT_NO_REPLY_REGEXP) }
    end

    context 'when a custom value has been set' do
      before { described_class.no_reply_regexp = /123/ }

      after do
        described_class.no_reply_regexp =
          described_class::DEFAULT_NO_REPLY_REGEXP
      end

      it { is_expected.to eq(/123/) }
    end

  end

  describe '.invalid_reply_addresses' do
    subject { described_class.invalid_reply_addresses }

    context 'when a custom value has not been set' do
      it { is_expected.to eq(described_class::DEFAULT_INVALID_REPLY_ADDRESSES) }
    end

    context 'when a custom value has been set' do
      before { described_class.invalid_reply_addresses = %w(A@example.com) }

      after do
        described_class.invalid_reply_addresses =
          described_class::DEFAULT_INVALID_REPLY_ADDRESSES
      end

      it { is_expected.to eq(%W(a@example.com)) }
    end

  end

end
