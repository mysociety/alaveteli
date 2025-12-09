require 'spec_helper'

RSpec.describe ReplyToAddressValidator do
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

      it { is_expected.to eq(%w(a@example.com)) }
    end
  end

  describe '.valid?' do
    it "returns true a valid email is fine" do
      expect(ReplyToAddressValidator.valid?('team@mysociety.org')).to eq true
    end

    it "returns false if postmaster email is bad" do
      expect(ReplyToAddressValidator.valid?('postmaster@mysociety.org')).
        to eq false
    end

    it "returns false if Mailer-Daemon email is bad" do
      expect(ReplyToAddressValidator.valid?('Mailer-Daemon@mysociety.org')).
        to eq false
    end

    it "returns false if case mangled MaIler-DaemOn email is bad" do
      expect(ReplyToAddressValidator.valid?('MaIler-DaemOn@mysociety.org')).
        to eq false
    end

    it "returns false if Auto_Reply email is bad" do
      expect(ReplyToAddressValidator.valid?('Auto_Reply@mysociety.org')).
        to eq false
    end

    it "returns false if DoNotReply email is bad" do
      expect(ReplyToAddressValidator.valid?('DoNotReply@tube.tfl.org.uk')).
        to eq false
    end

    it "returns false if no reply email is bad" do
      expect(ReplyToAddressValidator.valid?('noreply@tube.tfl.org.uk')).
        to eq false
      expect(ReplyToAddressValidator.valid?('no.reply@tube.tfl.org.uk')).
        to eq false
      expect(ReplyToAddressValidator.valid?('no-reply@tube.tfl.org.uk')).
        to eq false
    end

    context 'when invalid reply addresses have been configured' do
      around do |example|
        orig = ReplyToAddressValidator.invalid_reply_addresses
        ReplyToAddressValidator.invalid_reply_addresses = %w(a@example.com)
        example.call
        ReplyToAddressValidator.invalid_reply_addresses = orig
      end

      it 'returns false if the full email is invalid' do
        expect(ReplyToAddressValidator.valid?('a@example.com')).to eq false
      end

      it 'returns true if the full email is not invalid' do
        expect(ReplyToAddressValidator.valid?('b@example.com')).to eq true
      end
    end
  end
end
