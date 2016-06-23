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

    it 'returns nil if a delivery status cannot be parsed from the line' do
      expect(described_class.new('garbage').delivery_status).to eq(nil)
    end

    it 'parses a :sent line' do
      line = 'Oct  3 16:39:38 host postfix/smtp[7676]: CB55836EE58C: to=<foi@some.gov.au>, relay=aspmx.l.google.com[74.125.25.27]:25, delay=2.5, delays=0.13/0.02/1.7/0.59, dsn=2.0.0, status=sent (250 2.0.0 OK 1349246383 j9si1676296paw.328)'
      expected = MailServerLog::PostfixDeliveryStatus.new(:sent)
      expect(described_class.new(line).delivery_status).to eq(expected)
    end

    it 'parses a :deferred line' do
      line = 'Oct  3 16:39:38 host postfix/smtp[1681]: 9634B16F7F7: to=<kdent@example.com>, relay=none, delay=46, status=deferred (connect to 216.150.150.131[216.150.150.131]: No route to host)'
      expected =
        MailServerLog::PostfixDeliveryStatus.
          new(:deferred)
      expect(described_class.new(line).delivery_status).to eq(expected)
    end

    it 'parses a :bounced line' do
      line = 'Oct 10 13:22:49 host postfix/smtp[11876]: 6FB9036F1307: to=<foo@example.com>, relay=mta7.am0.yahoodns.net[74.6.136.244]:25, delay=1.5, delays=0.03/0/0.48/1, dsn=5.0.0, status=bounced (host mta7.am0.yahoodns.net[74.6.136.244] said: 554 delivery error: dd Sorry your message to foo@example.com cannot be delivered. This account has been disabled or discontinued [#102]. - mta1272.mail.sk1.yahoo.com (in reply to end of DATA command))'
      expected =
        MailServerLog::PostfixDeliveryStatus.
          new(:bounced)
      expect(described_class.new(line).delivery_status).to eq(expected)
    end

    it 'parses a :expired line' do
      line = 'Oct 10 13:22:49 host postfix/qmgr[1706]: A323688C523:from=<foo@example.com>, status=expired, returned to sender'
      expected =
        MailServerLog::PostfixDeliveryStatus.
          new(:expired)
      expect(described_class.new(line).delivery_status).to eq(expected)
    end

  end

end
