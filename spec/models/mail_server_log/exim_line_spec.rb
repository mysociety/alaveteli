# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe MailServerLog::EximLine do

  describe '.new' do

    it 'requires a line argument' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

  end

  describe '#to_s' do

    it 'returns the log line' do
      line = '2016-02-03 06:58:11 [16003] 1aQrOE-0004A7-TL <= request-313973-1650c56a@localhost U=alaveteli P=local S=3098 id=ogm-512169+56b3a50ac0cf4-6717@localhost T="Freedom of Information request - Rspec" from <request-313973-1650c56a@localhost> for foi@body.example.com foi@body.example.com'
      expect(described_class.new(line).to_s).to eq(line)
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

  describe '#inspect' do

    it 'returns the default format' do
      subject = described_class.new('log line')
      obj_id = "0x00%x" % (subject.object_id << 1)
      expected =
        %Q(#<#{described_class}:#{obj_id} @line="log line">)
      expect(subject.inspect).to eq(expected)
    end

  end

  describe '#delivery_status' do

    it 'returns nil if a delivery status cannot be parsed from the line' do
      expect(described_class.new('garbage').delivery_status).to eq(nil)
    end

    it 'parses a :normal_message_delivery line' do
      line = '2015-10-30 19:24:16 [17817] 1ZsFHb-0004dK-SM => authority@example.com F=<request-123-abc987@example.net> P=<request-123-abc987@example.net> R=dnslookup T=remote_smtp S=2297 H=cluster2.gsi.messagelabs.com [127.0.0.1]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail221.messagelabs.com" C="250 ok 1446233056 qp 26062 server-4.tower-221.messagelabs.com!1446233056!7679409!1" QT=1s DT=0s'
      expected = MailServerLog::EximDeliveryStatus.new(:normal_message_delivery)
      expect(described_class.new(line).delivery_status).to eq(expected)
    end

    it 'parses an :additional_address_in_same_delivery line' do
      line = '2016-06-03 14:22:11 [31522] 1b8p3C-0008CN-Vl -> authority@example.com <Authority@example.com> F=<request-123-abc987@example.net> P=<request-123-abc987@example.net> R=dnslookup T=remote_smtp S=5745 H=cluster5.eu.messagelabs.com [85.158.138.179]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail169.messagelabs.com" C="250 ok 1464960131 qp 11694 server-9.tower-169.messagelabs.com!1464960131!41697448!1" QT=1s DT=0s'
      expected =
        MailServerLog::EximDeliveryStatus.
          new(:additional_address_in_same_delivery)
      expect(described_class.new(line).delivery_status).to eq(expected)
    end

    it 'parses a :cutthrough_message_delivery line' do
      # Can't find a real example for this
      line = '2015-10-30 19:24:16 [17817] 1ZsFHb-0004dK-SM >> authority@example.com ???'
      expected =
        MailServerLog::EximDeliveryStatus.new(:cutthrough_message_delivery)
      expect(described_class.new(line).delivery_status).to eq(expected)
    end

    it 'parses a :delivery_deferred_temporary_problem line' do
      line = '2016-06-03 11:03:18 [13879] 1b8lwj-0003bo-6W == authority@example.com R=dnslookup T=remote_smtp defer (-44): SMTP error from remote mail server after RCPT TO:<authority@example.com>: host eu-smtp-inbound-1.mimecast.com [195.130.217.211]: 451 Internal resource temporarily unavailable - https://community.mimecast.com/docs/DOC-1369#451'
      expected =
        MailServerLog::EximDeliveryStatus.
          new(:delivery_deferred_temporary_problem)
      expect(described_class.new(line).delivery_status).to eq(expected)
    end

    it 'parses a :delivery_suppressed_by_N line' do
      # Can't find a real example for this
      line = '2015-10-30 19:24:16 [17817] 1ZsFHb-0004dK-SM *> authority@example.com ???'
      expected =
        MailServerLog::EximDeliveryStatus.new(:delivery_suppressed_by_N)
      expect(described_class.new(line).delivery_status).to eq(expected)
    end

    it 'parses a :delivery_failed_address_bounced line' do
      line = '2016-06-03 01:21:52 [22942] 1b8cs4-0005xz-6g ** invalid@example.com F=<do-not-reply-to-this-address@example.net>: Unrouteable address'
      expected =
        MailServerLog::EximDeliveryStatus.new(:delivery_failed_address_bounced)
      expect(described_class.new(line).delivery_status).to eq(expected)
    end

    it 'parses a :message_arrival line' do
      line = '2016-06-03 17:07:57 [28168] 1b8rdd-0007KK-8q <= authority@example.com H=localhost [127.0.0.1]:39362 I=[127.0.0.1]:25 P=esmtp S=99310 id=fd14e1d536e94486b1de551709543fc3@PDC5EXC108.example.com T="Freedom of Information request - Some information please" from <authority@example.com> for localhost'
      expected = MailServerLog::EximDeliveryStatus.new(:message_arrival)
      expect(described_class.new(line).delivery_status).to eq(expected)
    end

    it 'parses a :bounce_arrival line' do
      line = '2016-04-06 12:01:08 [14935] 1anlCu-0003st-1p <= <> R=1anlCt-0003sm-LG U=Debian-exim P=local S=2934 T="Mail delivery failed: returning message to sender" from <> for request-326806-hk82iwn7@localhost'
      expected = MailServerLog::EximDeliveryStatus.new(:bounce_arrival)
      expect(described_class.new(line).delivery_status).to eq(expected)
    end

  end

end
