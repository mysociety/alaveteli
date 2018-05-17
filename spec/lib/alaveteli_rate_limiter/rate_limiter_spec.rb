# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliRateLimiter::RateLimiter do
  let(:window) { AlaveteliRateLimiter::Window.new(1, :hour) }
  let(:rule) { AlaveteliRateLimiter::Rule.new(:test, 1, window) }

  describe '.new' do

    it 'requires a Rule' do
      expect { subject }.to raise_error(ArgumentError)
    end

    it 'accepts a Rule' do
      subject = described_class.new(rule)
      expect(subject.rule).to eq(rule)
    end

    it 'creates a default backend' do
      subject = described_class.new(rule)

      path =
        Pathname.
          new(Rails.root + "tmp/#{ subject.rule.name }_rate_limiter.pstore")

      expected =
        AlaveteliRateLimiter::Backends::PStoreDatabase.new(path: path)

      expect(subject.backend).to eq(expected)
    end

    it 'allows a custom backend' do
      backend = double
      subject = described_class.new(rule, backend: backend)
      expect(subject.backend).to eq(backend)
    end

  end

  describe '#rule' do

    it 'returns the rule attribute' do
      expect(described_class.new(rule).rule).to eq(rule)
    end

  end

  describe '#backend' do

    it 'returns the backend attribute' do
      backend = double
      subject = described_class.new(rule, backend: backend)
      expect(subject.backend).to eq(backend)
    end

  end

  describe '#records' do

    it 'returns the records in the backend' do
      id = '1'
      backend = double
      records = [10.days.ago, 1.day.ago].map(&:to_datetime)
      allow(backend).to receive(:get).with(id).and_return(records)
      subject = described_class.new(rule, backend: backend)
      expect(subject.records(id)).to eq(records)
    end

  end

  describe '#record' do

    it 'records an event for the id in the backend' do
      backend = double
      subject = described_class.new(rule, backend: backend)
      expect(backend).to receive(:record).with('1')
      subject.record('1')
    end

    it 'converts to a String key' do
      backend = double
      subject = described_class.new(rule, backend: backend)
      expect(backend).to receive(:record).with('1')
      subject.record(1)
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
          new(Rails.root + "tmp/#{ rule.name }_rate_limiter.pstore")

      backend =
        AlaveteliRateLimiter::Backends::PStoreDatabase.new(path: path)

      subject = described_class.new(rule, backend: backend)

      id = '1'

      purged = 10.days.ago
      time_travel_to(purged) do
        subject.record(id)
      end

      time = Time.zone.now.to_datetime

      time_travel_to(time) do
        subject.record!(id)
        expect(subject.records(id)).not_to include(purged)
      end

      File.delete(path)
    end

  end

  describe '#limit?' do
    let(:rule) { AlaveteliRateLimiter::Rule.new(:test, 1, double) }

    it 'returns true if the records break the rule limit' do
      allow(rule).to receive(:limit?).and_return(true)
      subject = described_class.new(rule)
      expect(subject.limit?('1')).to eq(true)
    end

    it 'returns false if the records are within the rule limit' do
      allow(rule).to receive(:limit?).and_return(false)
      subject = described_class.new(rule)
      expect(subject.limit?('1')).to eq(false)
    end

  end

end
