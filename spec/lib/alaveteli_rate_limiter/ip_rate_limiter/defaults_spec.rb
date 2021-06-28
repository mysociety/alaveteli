require 'spec_helper'

describe AlaveteliRateLimiter::IPRateLimiter::Defaults do

  describe '.new' do

    it 'sets the the default whitelist' do
      expect(subject.whitelist).
        to eq(AlaveteliRateLimiter::IPRateLimiter::Whitelist.new)
    end

    it 'sets the whitelist if the option is nil' do
      subject = described_class.new(:whitelist => nil)
      expect(subject.whitelist).
        to eq(AlaveteliRateLimiter::IPRateLimiter::Whitelist.new)
    end

    it 'sets the custom whitelist' do
      whitelist = double
      subject = described_class.new(:whitelist => whitelist)
      expect(subject.whitelist).to eq(whitelist)
    end

    it 'sets the the default event_rules' do
      expect(subject.event_rules).to eq(described_class::EVENT_RULES)
    end

    it 'sets the event_rules if the option is nil' do
      subject = described_class.new(:event_rules => nil)
      expect(subject.event_rules).to eq(described_class::EVENT_RULES)
    end

    it 'sets the custom event_rules' do
      event_rules = double
      subject = described_class.new(:event_rules => event_rules)
      expect(subject.event_rules).to eq(event_rules)
    end

  end

  describe '#whitelist' do

    it 'returns the whitelist' do
      expect(subject.whitelist).
        to eq(AlaveteliRateLimiter::IPRateLimiter::Whitelist.new)
    end

  end

  describe '#whitelist=' do

    it 'sets the whitelist' do
      whitelist = double
      subject.whitelist = whitelist
      expect(subject.whitelist).to eq(whitelist)
    end

  end

  describe '#event_rules' do

    it 'returns the event_rules' do
      expect(subject.event_rules).to eq(described_class::EVENT_RULES)
    end

  end

  describe '#whitelist=' do

    it 'sets the whitelist' do
      event_rules = double
      subject.event_rules = event_rules
      expect(subject.event_rules).to eq(event_rules)
    end

  end

  describe '#==' do

    it 'is equal if its attributes are identical' do
      opts = { :whitelist => double }
      subject = described_class.new(opts)
      expect(subject).to eq(subject.dup)
    end

    it 'is not equal if any of the attributes vary' do
      whitelist = AlaveteliRateLimiter::IPRateLimiter::Whitelist.
        new(%w(127.0.0.1 0.0.0.1))
      subject2 = described_class.new(:whitelist => whitelist)
      expect(subject).not_to eq(subject2)
    end

  end

end
