# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliRateLimiter::IPRateLimiter do

  after(:each) do
    described_class.defaults!
  end

  describe '.defaults' do

    it 'sets the defaults' do
      expect(described_class.defaults).
        to eq(AlaveteliRateLimiter::IPRateLimiter::Defaults.new)
    end

    it 'allows custom defaults to be set' do
      whitelist = double

      defaults = AlaveteliRateLimiter::IPRateLimiter::Defaults.
        new(whitelist: whitelist)

      described_class.set_defaults do |defaults|
        defaults.whitelist = whitelist
      end

      expect(described_class.defaults).to eq(defaults)
    end

  end

  describe '.new' do

    it 'requires a Rule' do
      expect { subject }.to raise_error(ArgumentError)
    end

    it 'accepts a Rule' do
      rule = AlaveteliRateLimiter::Rule.new(:test, 1, double)
      subject = described_class.new(rule)
      expect(subject.rule).to eq(rule)
    end

    it 'looks up a Symbol rule from the configured defaults' do
      rule_attrs = { count: 3, window: { value: 1, unit: :hour } }

      described_class.set_defaults do |defaults|
        defaults.event_rules = { signup: rule_attrs }
      end

      rule =
        AlaveteliRateLimiter::Rule.from_hash(rule_attrs.merge(name: :signup))

      expect(described_class.new(:signup).rule).to eq(rule)
    end

    it 'raises an error if a Symbol rule is not a configured default' do
      described_class.set_defaults do |defaults|
        defaults.event_rules = {}
      end
      expect { described_class.new(:signup) }.to raise_error(KeyError)
    end

    it 'creates a default backend' do
      subject = described_class.new(:signup)

      path =
        Pathname.
          new(Rails.root + "tmp/#{ subject.rule.name }_ip_rate_limiter.pstore")

      expected =
        AlaveteliRateLimiter::Backends::PStoreDatabase.new(path: path)

      expect(subject.backend).to eq(expected)
    end

    it 'allows a custom backend' do
      backend = double
      subject = described_class.new(:signup, backend: backend)
      expect(subject.backend).to eq(backend)
    end

    it 'creates a default whitelist' do
      subject = described_class.new(:signup)
      expect(subject.whitelist).to eq(described_class.defaults.whitelist)
    end

    it 'allows a custom whitelist' do
      whitelist = double
      subject = described_class.new(:signup, whitelist: whitelist)
      expect(subject.whitelist).to eq(whitelist)
    end

  end

  describe '#rule' do

    it 'returns the rule attribute' do
      rule = AlaveteliRateLimiter::Rule.new(:signup, 1, double)
      expect(described_class.new(rule).rule).to eq(rule)
    end

  end

  describe '#whitelist' do

    it 'returns the whitelist attribute' do
      whitelist = double
      subject = described_class.new(:signup, whitelist: whitelist)
      expect(subject.whitelist).to eq(whitelist)
    end

  end

  describe '#backend' do

    it 'returns the backend attribute' do
      backend = double
      subject = described_class.new(:signup, backend: backend)
      expect(subject.backend).to eq(backend)
    end

  end

  describe '#records' do

    it 'returns the records in the backend' do
      ip = '127.0.0.1'
      backend = double
      records = [10.days.ago, 1.day.ago].map(&:to_datetime)
      allow(backend).to receive(:get).with(ip).and_return(records)
      subject = described_class.new(:signup, backend: backend)
      expect(subject.records(ip)).to eq(records)
    end

  end

  describe '#record' do

    it 'records an event for the IP in the backend' do
      backend = double
      subject = described_class.new(:signup, backend: backend)
      expect(backend).to receive(:record).with('127.0.0.1')
      subject.record('127.0.0.1')
    end

    it 'converts an IPAddr to a String key' do
      backend = double
      subject = described_class.new(:signup, backend: backend)
      expect(backend).to receive(:record).with('127.0.0.1')
      subject.record(IPAddr.new('127.0.0.1'))
    end

    it 'cleans a poorly formatted IP' do
      backend = double
      subject = described_class.new(:signup, backend: backend)
      expect(backend).to receive(:record).with('127.0.0.1')
      subject.record("  127.0.0.1\n")
    end

    it 'raises an error for an invalid IP address' do
      subject = described_class.new(:signup)
      expect { subject.record('invalid') }.to raise_error(ArgumentError)
    end

  end

  describe '#record!' do

    it 'purges old records before recording the new event' do
      attrs = { name: :test,
                count: 20,
                window: { value: 1, unit: :day } }

      rule = AlaveteliRateLimiter::Rule.from_hash(attrs)

      path =
        Pathname.
          new(Rails.root + "tmp/#{ rule.name }_ip_rate_limiter.pstore")

      backend =
        AlaveteliRateLimiter::Backends::PStoreDatabase.new(path: path)

      subject = described_class.new(rule, backend: backend)

      ip = '127.0.0.1'

      purged = 10.days.ago
      time_travel_to(purged) do
        subject.record(ip)
      end

      time = Time.zone.now.to_datetime

      time_travel_to(time) do
        subject.record!(ip)
        expect(subject.records(ip)).not_to include(purged)
      end

      File.delete(path)
    end

  end

  describe '#limit?' do

    it 'returns false if the IP is in the whitelist' do
      whitelist = AlaveteliRateLimiter::IPRateLimiter::Whitelist.new(%(0.0.0.0))
      subject = described_class.new(:signup, whitelist: whitelist)
      expect(subject.limit?('0.0.0.0')).to eq(false)
    end

    it 'returns true if the records break the rule limit' do
      rule = AlaveteliRateLimiter::Rule.new(:test, 1, double)
      allow(rule).to receive(:limit?).and_return(true)
      subject = described_class.new(rule)
      expect(subject.limit?('0.0.0.0')).to eq(true)
    end

    it 'returns false if the records are within the rule limit' do
      rule = AlaveteliRateLimiter::Rule.new(:test, 1, double)
      allow(rule).to receive(:limit?).and_return(false)
      subject = described_class.new(rule)
      expect(subject.limit?('0.0.0.0')).to eq(false)
    end

  end

end
