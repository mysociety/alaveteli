# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliTextMasker::TextMasks::EmailAddressMasker do

  let(:middleware) { lambda { |env| env } }

  describe '::EMAIL_REGEXP' do
    subject { described_class::EMAIL_REGEXP }
    it { is_expected.
          to eq(/(\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}\b)/) }
  end

  describe '::DEFAULT_EMAIL_REPLACEMENT' do
    subject { described_class::DEFAULT_EMAIL_REPLACEMENT }
    it { is_expected.to eq('[email address]') }
  end

  describe '.new' do

    it 'acts like a RegexpMasker' do
      expect(described_class.new(middleware)).
        to be_kind_of(AlaveteliTextMasker::TextMasks::RegexpMasker)
    end

    it 'sets a default regexp' do
      regexp = /(\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}\b)/
      expect(described_class.new(middleware).regexp).to eq(regexp)
    end

    it 'does not allow a custom regexp' do
      masker = described_class.new(middleware, :regexp => //)
      expect(masker.regexp).to eq(described_class::EMAIL_REGEXP)
    end

    it 'sets a default replacement' do
      replacement = described_class::DEFAULT_EMAIL_REPLACEMENT
      expect(described_class.new(middleware).replacement).to eq(replacement)
    end

    it 'allows a custom replacement' do
      masker = described_class.new(middleware, :replacement => 'gone')
      expect(masker.replacement).to eq('gone')
    end

  end

  describe '#call' do

    it 'masks an email address of the format name@example.com' do
      email = 'name@example.com'
      masker = described_class.new(middleware)
      expect(masker.call(email)).to eq('[email address]')
    end

    it 'uses a custom replacement string' do
      email = 'name@example.com'
      masker = described_class.new(middleware, :replacement => '[gone]')
      expect(masker.call(email)).to eq('[gone]')
    end

    it 'masks an email address of the format first.last@example.com' do
      email = 'first.last@example.com'
      masker = described_class.new(middleware)
      expect(masker.call(email)).to eq('[email address]')
    end

    it 'masks an email address of the format first.last@example.co.uk' do
      email = 'first.last@example.co.uk'
      masker = described_class.new(middleware)
      expect(masker.call(email)).to eq('[email address]')
    end

    it 'masks an email address of the format magic+name@example.com' do
      email = 'magic+name@example.com'
      masker = described_class.new(middleware)
      expect(masker.call(email)).to eq('[email address]')
    end

    it 'masks an email address amongst other text' do
      text = 'My email address is name@example.com. Can I have yours?'
      expected = 'My email address is [email address]. Can I have yours?'
      masker = described_class.new(middleware)
      expect(masker.call(text)).to eq(expected)
    end

  end

end
