# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe MailServerLog::EximDeliveryStatus do

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
      expect(described_class.new(:message_arrival).to_sym).to eq(:message_arrival)
    end

  end

  describe '#to_s' do

    it 'returns the status as a String' do
      expect(described_class.new(:message_arrival).to_s).to eq('message_arrival')
    end

  end

  describe '#inspect' do

    it 'returns the default format' do
      subject = described_class.new(:message_arrival)
      obj_id = "0x00%x" % (subject.object_id << 1)
      expected =
        %Q(#<#{described_class}:#{obj_id} @status=:message_arrival>)
      expect(subject.inspect).to eq(expected)
    end

  end

  describe '#<=>' do

    let(:statuses) do
      [:message_arrival,
       :additional_address_in_same_delivery,
       :cutthrough_message_delivery].map { |s| described_class.new(s) }
     end

     let(:sorted) do
       [:additional_address_in_same_delivery,
        :cutthrough_message_delivery,
        :message_arrival]
     end

    it { expect(statuses.sort.map(&:to_sym)).to eq(sorted) }
    it { expect(statuses.sort { |a,b| b <=> a }.map(&:to_sym)).to eq(sorted.reverse) }

    let(:a) { described_class.new(:additional_address_in_same_delivery) }
    let(:b) { described_class.new(:message_arrival) }

    it { expect(a > b).to eq(false) }
    it { expect(a < b).to eq(true) }
    it { expect(a >= b).to eq(false) }
    it { expect(a <= b).to eq(true) }
    it { expect(a == b).to eq(false) }

  end

  describe '#simple' do

    it 'returns :delivered when the status is :normal_message_delivery' do
      status = described_class.new(:normal_message_delivery)
      expect(status.simple).to eq(:delivered)
    end

    it 'returns :delivered when the status is :additional_address_in_same_delivery' do
      status = described_class.new(:additional_address_in_same_delivery)
      expect(status.simple).to eq(:delivered)
    end

    it 'returns :delivered when the status is :cutthrough_message_delivery' do
      status = described_class.new(:cutthrough_message_delivery)
      expect(status.simple).to eq(:delivered)
    end

    it 'returns :sent when the status is :message_arrival' do
      status = described_class.new(:message_arrival)
      expect(status.simple).to eq(:sent)
    end

    it 'returns :sent when the status is :delivery_deferred_temporary_problem' do
      status = described_class.new(:delivery_deferred_temporary_problem)
      expect(status.simple).to eq(:sent)
    end

    it 'returns :failed when the status is :delivery_suppressed_by_N' do
      status = described_class.new(:delivery_suppressed_by_N)
      expect(status.simple).to eq(:failed)
    end

    it 'returns :failed when the status is :delivery_failed_address_bounced' do
      status = described_class.new(:delivery_failed_address_bounced)
      expect(status.simple).to eq(:failed)
    end

    it 'returns :failed when the status is :bounce_arrival' do
      status = described_class.new(:bounce_arrival)
      expect(status.simple).to eq(:failed)
    end

  end

  describe '#delivered?' do

    it 'returns true when the simple status is :delivered' do
      status = described_class.new(:normal_message_delivery)
      expect(status.delivered?).to eq(true)
    end

    it 'returns false when the simple status is not :delivered' do
      status = described_class.new(:message_arrival)
      expect(status.delivered?).to eq(false)
    end

  end

  describe '#sent?' do

    it 'returns true when the simple status is :sent' do
      status = described_class.new(:delivery_deferred_temporary_problem)
      expect(status.sent?).to eq(true)
    end

    it 'returns false when the simple status is not :sent' do
      status = described_class.new(:bounce_arrival)
      expect(status.sent?).to eq(false)
    end

  end

  describe '#failed?' do

    it 'returns true when the simple status is :failed' do
      status = described_class.new(:delivery_failed_address_bounced)
      expect(status.failed?).to eq(true)
    end

    it 'returns false when the simple status is not :failed' do
      status = described_class.new(:message_arrival)
      expect(status.failed?).to eq(false)
    end

  end

  describe '#humanize' do

    it 'returns a humanized string for :delivered statuses' do
      status = described_class.new(:normal_message_delivery)
      expect(status.humanize).to eq('This message has been delivered.')
    end

    it 'returns a humanized string for :sent statuses' do
      status = described_class.new(:delivery_deferred_temporary_problem)
      expect(status.humanize).to eq('This message has been sent.')
    end

    it 'returns a humanized string for :failed statuses' do
      status = described_class.new(:delivery_failed_address_bounced)
      expect(status.humanize).to eq('This message could not be delivered.')
    end

  end

end
