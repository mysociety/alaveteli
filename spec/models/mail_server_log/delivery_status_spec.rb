# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe MailServerLog::DeliveryStatus do

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
      expect(described_class.new(:delivered).to_sym).to eq(:delivered)
    end

  end

  describe '#to_s' do

    it 'returns the status as a String' do
      expect(described_class.new(:sent).to_s).to eq('sent')
    end

  end

  describe '#inspect' do

    it 'returns the default format' do
      subject = described_class.new(:delivered)
      obj_id = "0x00%x" % (subject.object_id << 1)
      expected =
        %Q(#<#{described_class}:#{obj_id} @status=:delivered>)
      expect(subject.inspect).to eq(expected)
    end

  end

  describe '#<=>' do

    let(:statuses) do
      [:delivered,
       :unknown,
       :failed,
       :sent].map { |s| described_class.new(s) }
     end

     let(:sorted) do
       [:unknown,
        :failed,
        :sent,
        :delivered]
     end

    it { expect(statuses.sort.map(&:to_sym)).to eq(sorted) }
    it { expect(statuses.sort { |a,b| b <=> a }.map(&:to_sym)).to eq(sorted.reverse) }

    let(:a) { described_class.new(:sent) }
    let(:b) { described_class.new(:delivered) }

    it { expect(a > b).to eq(false) }
    it { expect(a < b).to eq(true) }
    it { expect(a >= b).to eq(false) }
    it { expect(a <= b).to eq(true) }
    it { expect(a == b).to eq(false) }

  end

  describe '#simple' do

    it 'returns the status' do
      expect(described_class.new(:sent).simple).to eq(:sent)
    end

  end

  describe '#delivered?' do

    it 'returns true when the status is :delivered' do
      status = described_class.new(:delivered)
      expect(status.delivered?).to eq(true)
    end

    it 'returns false when the status is not :delivered' do
      status = described_class.new(:sent)
      expect(status.delivered?).to eq(false)
    end

  end

  describe '#sent?' do

    it 'returns true when the status is :sent' do
      status = described_class.new(:sent)
      expect(status.sent?).to eq(true)
    end

    it 'returns true when the status is :delivered' do
      status = described_class.new(:delivered)
      expect(status.sent?).to eq(true)
    end

    it 'returns false when the status is not :sent' do
      status = described_class.new(:failed)
      expect(status.sent?).to eq(false)
    end

  end

  describe '#failed?' do

    it 'returns true when the status is :failed' do
      status = described_class.new(:failed)
      expect(status.failed?).to eq(true)
    end

    it 'returns false when the status is not :failed' do
      status = described_class.new(:delivered)
      expect(status.failed?).to eq(false)
    end

  end

  describe '#unknown?' do

    it 'returns true when the status is :unknown' do
      status = described_class.new(:unknown)
      expect(status.unknown?).to eq(true)
    end

    it 'returns false when the status is not :unknown' do
      status = described_class.new(:delivered)
      expect(status.unknown?).to eq(false)
    end

  end

  describe '#humanize' do

    it 'returns a humanized string for the :delivered status' do
      status = described_class.new(:delivered)
      expect(status.humanize).to eq('This message has been delivered.')
    end

    it 'returns a humanized string for the :sent status' do
      status = described_class.new(:sent)
      expect(status.humanize).to eq('This message has been sent.')
    end

    it 'returns a humanized string for the :failed status' do
      status = described_class.new(:failed)
      expect(status.humanize).to eq('This message could not be delivered.')
    end

    it 'returns a humanized string for the :unknown status' do
      status = described_class.new(:unknown)
      expect(status.humanize).
        to eq("We don't know the delivery status for this message.")
    end
  end

end
