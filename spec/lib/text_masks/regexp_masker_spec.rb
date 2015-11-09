# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliTextMasker::TextMasks::RegexpMasker do

  let(:middleware) { lambda { |env| env } }

  describe '.new' do

    it 'requires an app' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it 'raises an error if the app does not respond to #call' do
      expect { described_class.new(double) }.to raise_error(ArgumentError)
    end

    it 'requires a :regexp option' do
      expect { described_class.new(middleware) }.to raise_error(KeyError)
    end

    it 'sets a default replacement string' do
      masker = described_class.new(middleware, :regexp => //)
      expect(masker.replacement).to eq('[REDACTED]')
    end

  end

  describe '#regexp' do

    it 'returns the regexp' do
      masker = described_class.new(middleware, :regexp => //)
      expect(masker.regexp).to eq(//)
    end

  end

  describe '#replacement' do

    it 'returns the replacement string' do
      opts = { :regexp => //, :replacement => 'gone' }
      masker = described_class.new(middleware, opts)
      expect(masker.replacement).to eq('gone')
    end

  end

  describe '#call' do

    it 'replaces patterns matched by the regexp with the replacement' do
      text = 'A REPLACE_ME secret'
      masker = described_class.new(middleware, :regexp => /REPLACE_ME/)
      expect(masker.call(text)).to eq('A [REDACTED] secret')
    end

    it 'does not replace text that is not matched by the regexp' do
      text = 'A super secret'
      masker = described_class.new(middleware, :regexp => /REPLACE_ME/)
      expect(masker.call(text)).to eq('A super secret')
    end

  end

end
