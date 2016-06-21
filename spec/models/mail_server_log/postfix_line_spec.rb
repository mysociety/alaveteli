# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe MailServerLog::PostfixLine do

  describe '.new' do

    it 'requires a line argument' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

  end

  describe '#to_s' do

    it 'returns the log line' do
      line = 'Oct  2 08:57:45 vagrant-ubuntu-precise-64 postfix/pickup[7843]: E9B4F420D5: uid=1001 from=<foi+request-117-c99ae4f3@localhost>'
      expect(described_class.new(line).to_s).to eq(line)
    end

  end

  describe '#inspect' do

    it 'returns the default format' do
      subject = described_class.new('log line')
      obj_id = "0x00%x" % (subject.object_id << 1)
      expected =
        %Q(#<#{described_class}:#{obj_id} @line="log line">)
      expect(subject.inspect).to eq(expected)
    end

  end

  describe '#<=>' do

    let(:lines) { %w(A C B).map { |s| described_class.new(s) } }

    it { expect(lines.sort.map(&:to_s)).to eq(%w(A B C)) }
    it { expect(lines.sort { |a,b| b <=> a }.map(&:to_s)).to eq(%w(C B A)) }

    let(:a) { described_class.new('A') }
    let(:b) { described_class.new('B') }

    it { expect(a > b).to eq(false) }
    it { expect(a < b).to eq(true) }
    it { expect(a >= b).to eq(false) }
    it { expect(a <= b).to eq(true) }
    it { expect(a == b).to eq(false) }

  end

  describe '#delivery_status' do

    it 'returns an :sent PostfixDeliveryStatus' do
      expected = MailServerLog::PostfixDeliveryStatus.new(:sent)
      expect(described_class.new('anything').delivery_status).to eq(expected)
    end

  end

end
