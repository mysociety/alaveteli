# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe MailServerLog::PostfixDeliveryStatus do

  describe '.new' do

    it 'accepts an argument but ignores it' do
      expect(described_class.new(:ignored).to_sym).to eq(:sent)
    end

  end

  describe '#to_sym' do

    it 'returns :sent' do
      expect(subject.to_sym).to eq(:sent)
    end

  end

  describe '#to_s' do

    it 'returns the status as a String' do
      expect(subject.to_s).to eq('sent')
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

    let(:a) { described_class.new(:a) }
    let(:b) { described_class.new(:b) }

    it { expect(a > b).to eq(false) }
    it { expect(a < b).to eq(false) }
    it { expect(a >= b).to eq(true) }
    it { expect(a <= b).to eq(true) }
    it { expect(a == b).to eq(true) }

  end

  describe '#simple' do

     it 'returns :sent' do
      expect(subject.simple).to eq(:sent)
    end

  end

  describe '#delivered?' do

    it 'returns false' do
      expect(subject.delivered?).to eq(false)
    end

  end

  describe '#sent?' do

    it 'returns true' do
      expect(subject.sent?).to eq(true)
    end

  end

  describe '#failed?' do

    it 'returns false' do
      expect(subject.failed?).to eq(false)
    end

  end

  describe '#humanize' do

    it 'returns a humanized string' do
      expect(subject.humanize).to eq('This message has been sent.')
    end

  end

end
