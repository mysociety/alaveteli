require 'spec_helper'

describe AlaveteliRateLimiter::IPRateLimiter::Whitelist do

  describe '.new' do

    it 'sets an empty whitelist by default' do
      expect(subject.addresses).to be_empty
    end

    it 'takes a single item' do
      addr = IPAddr.new('0.0.0.0')
      subject = described_class.new(addr)
      expect(subject.addresses).to eq([addr])
    end

    it 'takes several items' do
      addrs = %w(0.0.0.1 0.0.0.2 0.0.0.3).map { |ip| IPAddr.new(ip) }
      subject = described_class.new(addrs)
      expect(subject.addresses).to eq(addrs)
    end

    it 'removes duplicate items' do
      addrs = %w(0.0.0.1 0.0.0.1 0.0.0.3).map { |ip| IPAddr.new(ip) }
      subject = described_class.new(addrs)
      expect(subject.addresses).to match_array([addrs.first, addrs.last])
    end

    it 'converts from a string item' do
      addr = '0.0.0.0'
      subject = described_class.new(addr)
      expect(subject.addresses).to eq([IPAddr.new(addr)])
    end

    it 'converts from string items' do
      addrs = %w(0.0.0.1 0.0.0.2 0.0.0.3)
      subject = described_class.new(addrs)
      expect(subject.addresses).to eq(addrs.map { |ip| IPAddr.new(ip) })
    end

    it 'raises an error for an invalid address' do
      expect { described_class.new('invalid') }.to raise_error(ArgumentError)
    end

    it 'raises an error for an invalid address in a list' do
      addrs = %w(0.0.0.1 invalid 0.0.0.3)
      expect { described_class.new(addrs) }.to raise_error(ArgumentError)
    end

  end

  describe '#include?' do

    it 'returns true if an address is whitelisted' do
      subject = described_class.new(%w(0.0.0.0 0.0.0.1))
      expect(subject.include?('0.0.0.0')).to eq(true)
    end

    it 'returns false if an address is not whitelisted' do
      subject = described_class.new(%w(0.0.0.1 0.0.0.2))
      expect(subject.include?('0.0.0.0')).to eq(false)
    end

    it 'allows an IPAddr address' do
      subject = described_class.new(%w(0.0.0.0 0.0.0.1))
      expect(subject.include?(IPAddr.new('0.0.0.0'))).to eq(true)
    end

    it 'raises an error for an invalid address' do
      subject = described_class.new(%w(0.0.0.0 0.0.0.1))
      expect { subject.include?('invalid') }.to raise_error(ArgumentError)
    end

  end

  describe '#==' do

    it 'returns true if the address list is the same' do
      subject = described_class.new(%w(0.0.0.0 0.0.0.1))
      expect(subject).to eq(subject.dup)
    end

    it 'returns false if the address list is different' do
      subject1 = described_class.new(%w(0.0.0.0 0.0.0.1))
      subject2 = described_class.new(%w(0.0.0.0 0.0.0.3))
      expect(subject1).not_to eq(subject2)
    end

  end

end
