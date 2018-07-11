# -*- encoding : utf-8 -*-
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

end
