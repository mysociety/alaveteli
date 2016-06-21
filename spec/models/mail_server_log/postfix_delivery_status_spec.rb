# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe MailServerLog::PostfixDeliveryStatus do

  describe '.new' do

    it 'requires a status argument' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it 'requires a valid status' do
      expect { described_class.new(:invalid) }.to raise_error(ArgumentError)
    end

  end

  describe '#to_sym' do

    it 'returns the status as a Symbol' do
      expect(described_class.new(:deferred).to_sym).to eq(:deferred)
    end

  end

  describe '#to_s' do

    it 'returns the status as a String' do
      expect(described_class.new(:deferred).to_s).to eq('deferred')
    end

  end

  describe '#inspect' do

    it 'returns the default format' do
      subject = described_class.new(:sent)
      obj_id = "0x00%x" % (subject.object_id << 1)
      expected =
        %Q(#<#{described_class}:#{obj_id} @status=:sent>)
      expect(subject.inspect).to eq(expected)
    end

  end

  describe '#<=>' do

    let(:statuses) do
      [:deferred,
       :expired,
       :bounced].map { |s| described_class.new(s) }
     end

     let(:sorted) do
       [:bounced,
        :deferred,
        :expired]
     end

    it { expect(statuses.sort.map(&:to_sym)).to eq(sorted) }
    it { expect(statuses.sort { |a,b| b <=> a }.map(&:to_sym)).to eq(sorted.reverse) }

    let(:a) { described_class.new(:bounced) }
    let(:b) { described_class.new(:deferred) }

    it { expect(a > b).to eq(false) }
    it { expect(a < b).to eq(true) }
    it { expect(a >= b).to eq(false) }
    it { expect(a <= b).to eq(true) }
    it { expect(a == b).to eq(false) }

  end

  describe '#simple' do

    it 'returns :delivered when the status is :sent' do
      status = described_class.new(:sent)
      expect(status.simple).to eq(:delivered)
    end

    it 'returns :sent when the status is :deferred' do
      status = described_class.new(:deferred)
      expect(status.simple).to eq(:sent)
    end

    it 'returns :failed when the status is :bounced' do
      status = described_class.new(:bounced)
      expect(status.simple).to eq(:failed)
    end

    it 'returns :failed when the status is :expired' do
      status = described_class.new(:expired)
      expect(status.simple).to eq(:failed)
    end

  end

  describe '#delivered?' do

    it 'returns true when the simple status is :delivered' do
      status = described_class.new(:sent)
      expect(status.delivered?).to eq(true)
    end

    it 'returns false when the simple status is not :delivered' do
      status = described_class.new(:deferred)
      expect(status.delivered?).to eq(false)
    end

  end

  describe '#sent?' do

    it 'returns true when the simple status is :sent' do
      status = described_class.new(:deferred)
      expect(status.sent?).to eq(true)
    end

    it 'returns false when the simple status is not :sent' do
      status = described_class.new(:bounced)
      expect(status.sent?).to eq(false)
    end

  end

  describe '#failed?' do

    it 'returns true when the simple status is :failed' do
      status = described_class.new(:bounced)
      expect(status.failed?).to eq(true)
    end

    it 'returns false when the simple status is not :failed' do
      status = described_class.new(:sent)
      expect(status.failed?).to eq(false)
    end

  end

  describe '#humanize' do

    it 'returns a humanized string for :delivered statuses' do
      status = described_class.new(:sent)
      expect(status.humanize).to eq('This message has been delivered.')
    end

    it 'returns a humanized string for :sent statuses' do
      status = described_class.new(:deferred)
      expect(status.humanize).to eq('This message has been sent.')
    end

    it 'returns a humanized string for :failed statuses' do
      status = described_class.new(:bounced)
      expect(status.humanize).to eq('This message could not be delivered.')
    end

  end

end
