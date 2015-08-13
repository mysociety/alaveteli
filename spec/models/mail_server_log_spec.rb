# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: mail_server_logs
#
#  id                      :integer          not null, primary key
#  mail_server_log_done_id :integer
#  info_request_id         :integer
#  order                   :integer          not null
#  line                    :text             not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MailServerLog do
  describe ".load_file" do
    before :each do
      allow(AlaveteliConfiguration).to receive(:incoming_email_domain).and_return("example.com")
      File.stub_chain(:stat, :mtime).and_return(DateTime.new(2012, 10, 10))
    end

    let(:log) {[
                 "This is a line of a logfile relevant to foi+request-1234@example.com",
                 "This is the second line for the same foi+request-1234@example.com email address"
    ]}

    let(:ir) { info_requests(:fancy_dog_request) }

    it "loads relevant lines of an uncompressed exim log file" do
      expect(File).to receive(:open).with("/var/log/exim4/exim-mainlog-2012-10-10", "r").and_return(log)
      expect(InfoRequest).to receive(:find_by_incoming_email).with("request-1234@example.com").twice.and_return(ir)
      MailServerLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")

      expect(ir.mail_server_logs.count).to eq(2)
      log = ir.mail_server_logs[0]
      expect(log.order).to eq(1)
      expect(log.line).to eq("This is a line of a logfile relevant to foi+request-1234@example.com")

      log = ir.mail_server_logs[1]
      expect(log.order).to eq(2)
      expect(log.line).to eq("This is the second line for the same foi+request-1234@example.com email address")
    end

    it "doesn't load the log file twice if it's unchanged" do
      expect(File).to receive(:open).with("/var/log/exim4/exim-mainlog-2012-10-10", "r").once.and_return([])

      MailServerLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
      MailServerLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
    end

    it "loads the log file again if it's changed" do
      expect(File).to receive(:open).with("/var/log/exim4/exim-mainlog-2012-10-10", "r").twice.and_return([])
      MailServerLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
      File.stub_chain(:stat, :mtime).and_return(DateTime.new(2012, 10, 11))
      MailServerLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
    end

    it "doesn't end up with two copies of each line when the same file is actually loaded twice" do
      expect(File).to receive(:open).with("/var/log/exim4/exim-mainlog-2012-10-10", "r").twice.and_return(log)
      allow(InfoRequest).to receive(:find_by_incoming_email).with("request-1234@example.com").and_return(ir)

      MailServerLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
      expect(ir.mail_server_logs.count).to eq(2)

      File.stub_chain(:stat, :mtime).and_return(DateTime.new(2012, 10, 11))
      MailServerLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
      expect(ir.mail_server_logs.count).to eq(2)
    end

    it "easily handles gzip compress log files" do
      expect(File).not_to receive(:open)
      expect(Zlib::GzipReader).to receive(:open).with("/var/log/exim4/exim-mainlog-2012-10-10.gz").and_return([])
      MailServerLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10.gz")
    end
  end

  describe ".email_addresses_on_line" do
    before :each do
      allow(AlaveteliConfiguration).to receive(:incoming_email_domain).and_return("example.com")
      allow(AlaveteliConfiguration).to receive(:incoming_email_prefix).and_return("foi+")
    end

    it "recognises a single incoming email" do
      expect(MailServerLog.email_addresses_on_line("a random log line foi+request-14-e0e09f97@example.com has an email")).to eq(
        ["foi+request-14-e0e09f97@example.com"]
      )
    end

    it "recognises two email addresses on the same line" do
      expect(MailServerLog.email_addresses_on_line("two email addresses here foi+request-10-1234@example.com and foi+request-14-e0e09f97@example.com")).to eq(
        ["foi+request-10-1234@example.com", "foi+request-14-e0e09f97@example.com"]
      )
    end

    it "returns an empty array when there is an email address from a different domain" do
      expect(MailServerLog.email_addresses_on_line("other foi+request-10-1234@foo.com")).to be_empty
    end

    it "ignores an email with a different prefix" do
      expect(MailServerLog.email_addresses_on_line("foitest+request-14-e0e09f97@example.com")).to be_empty
    end

    it "ignores an email where the . is substituted for something else" do
      expect(MailServerLog.email_addresses_on_line("foi+request-14-e0e09f97@exampledcom")).to be_empty
    end
  end

  context "Postfix" do
    let(:log) {[
                 "Oct  3 16:39:35 host postfix/pickup[2257]: CB55836EE58C: uid=1003 from=<foitest+request-14-e0e09f97@example.com>",
                 "Oct  3 16:39:35 host postfix/cleanup[7674]: CB55836EE58C: message-id=<ogm-15+506bdda7a4551-20ee@example.com>",
                 "Oct  3 16:39:35 host postfix/qmgr[1673]: 9634B16F7F7: from=<foitest+request-10-1234@example.com>, size=368, nrcpt=1 (queue active)",
                 "Oct  3 16:39:35 host postfix/qmgr[15615]: CB55836EE58C: from=<foitest+request-14-e0e09f97@example.com>, size=1695, nrcpt=1 (queue active)",
                 "Oct  3 16:39:38 host postfix/smtp[7676]: CB55836EE58C: to=<foi@some.gov.au>, relay=aspmx.l.google.com[74.125.25.27]:25, delay=2.5, delays=0.13/0.02/1.7/0.59, dsn=2.0.0, status=sent (250 2.0.0 OK 1349246383 j9si1676296paw.328)",
                 "Oct  3 16:39:38 host postfix/smtp[1681]: 9634B16F7F7: to=<kdent@example.com>, relay=none, delay=46, status=deferred (connect to 216.150.150.131[216.150.150.131]: No route to host)",
                 "Oct  3 16:39:38 host postfix/qmgr[15615]: CB55836EE58C: removed",
    ]}

    describe ".load_postfix_log_data" do
      # Postfix logs for a single email go over multiple lines. They are all tied together with the Queue ID.
      # See http://onlamp.com/onlamp/2004/01/22/postfix.html
      it "loads the postfix log and untangles seperate email transactions using the queue ID" do
        allow(AlaveteliConfiguration).to receive(:incoming_email_domain).and_return("example.com")
        allow(log).to receive(:rewind)
        ir1 = info_requests(:fancy_dog_request)
        ir2 = info_requests(:naughty_chicken_request)
        allow(InfoRequest).to receive(:find_by_incoming_email).with("request-14-e0e09f97@example.com").and_return(ir1)
        allow(InfoRequest).to receive(:find_by_incoming_email).with("request-10-1234@example.com").and_return(ir2)
        MailServerLog.load_postfix_log_data(log, MailServerLogDone.new(:filename => "foo", :last_stat => DateTime.now))
        # TODO: Check that each log line is attached to the correct request
        expect(ir1.mail_server_logs.count).to eq(5)
        expect(ir1.mail_server_logs[0].order).to eq(1)
        expect(ir1.mail_server_logs[0].line).to eq("Oct  3 16:39:35 host postfix/pickup[2257]: CB55836EE58C: uid=1003 from=<foitest+request-14-e0e09f97@example.com>")
        expect(ir1.mail_server_logs[1].order).to eq(2)
        expect(ir1.mail_server_logs[1].line).to eq("Oct  3 16:39:35 host postfix/cleanup[7674]: CB55836EE58C: message-id=<ogm-15+506bdda7a4551-20ee@example.com>")
        expect(ir1.mail_server_logs[2].order).to eq(4)
        expect(ir1.mail_server_logs[2].line).to eq("Oct  3 16:39:35 host postfix/qmgr[15615]: CB55836EE58C: from=<foitest+request-14-e0e09f97@example.com>, size=1695, nrcpt=1 (queue active)")
        expect(ir1.mail_server_logs[3].order).to eq(5)
        expect(ir1.mail_server_logs[3].line).to eq("Oct  3 16:39:38 host postfix/smtp[7676]: CB55836EE58C: to=<foi@some.gov.au>, relay=aspmx.l.google.com[74.125.25.27]:25, delay=2.5, delays=0.13/0.02/1.7/0.59, dsn=2.0.0, status=sent (250 2.0.0 OK 1349246383 j9si1676296paw.328)")
        expect(ir1.mail_server_logs[4].order).to eq(7)
        expect(ir1.mail_server_logs[4].line).to eq("Oct  3 16:39:38 host postfix/qmgr[15615]: CB55836EE58C: removed")
        expect(ir2.mail_server_logs.count).to eq(2)
        expect(ir2.mail_server_logs[0].order).to eq(3)
        expect(ir2.mail_server_logs[0].line).to eq("Oct  3 16:39:35 host postfix/qmgr[1673]: 9634B16F7F7: from=<foitest+request-10-1234@example.com>, size=368, nrcpt=1 (queue active)")
        expect(ir2.mail_server_logs[1].order).to eq(6)
        expect(ir2.mail_server_logs[1].line).to eq("Oct  3 16:39:38 host postfix/smtp[1681]: 9634B16F7F7: to=<kdent@example.com>, relay=none, delay=46, status=deferred (connect to 216.150.150.131[216.150.150.131]: No route to host)")
      end
    end

    describe ".scan_for_postfix_queue_ids" do
      it "returns the queue ids of interest with the connected email addresses" do
        allow(AlaveteliConfiguration).to receive(:incoming_email_domain).and_return("example.com")
        expect(MailServerLog.scan_for_postfix_queue_ids(log)).to eq({
          "CB55836EE58C" => ["request-14-e0e09f97@example.com"],
          "9634B16F7F7" => ["request-10-1234@example.com"]
        })
      end
    end

    describe ".extract_postfix_queue_id_from_syslog_line" do
      it "returns nil if there is no queue id" do
        expect(MailServerLog.extract_postfix_queue_id_from_syslog_line("Oct  7 07:16:48 kedumba postfix/smtp[14294]: connect to mail.neilcopp.com.au[110.142.151.66]:25: Connection refused")).to be_nil
      end
    end

    describe ".request_postfix_sent?" do
      it "returns true when the logs say the message was sent" do
        ir = info_requests(:fancy_dog_request)
        ir.mail_server_logs.create!(:line => "Oct 10 16:58:38 kedumba postfix/smtp[26358]: A664436F218D: to=<contact@openaustraliafoundation.org.au>, relay=aspmx.l.google.com[74.125.25.26]:25, delay=2.7, delays=0.16/0.02/1.8/0.67, dsn=2.0.0, status=sent (250 2.0.0 OK 1349848723 e6si653316paw.346)", :order => 1)
        expect(MailServerLog.request_postfix_sent?(ir)).to be true
      end

      it "returns false when the logs say the message hasn't been sent" do
        ir = info_requests(:fancy_dog_request)
        ir.mail_server_logs.create!(:line => "Oct 10 13:22:49 kedumba postfix/smtp[11876]: 6FB9036F1307: to=<foo@example.com>, relay=mta7.am0.yahoodns.net[74.6.136.244]:25, delay=1.5, delays=0.03/0/0.48/1, dsn=5.0.0, status=bounced (host mta7.am0.yahoodns.net[74.6.136.244] said: 554 delivery error: dd Sorry your message to foo@example.com cannot be delivered. This account has been disabled or discontinued [#102]. - mta1272.mail.sk1.yahoo.com (in reply to end of DATA command))", :order => 1)
        expect(MailServerLog.request_postfix_sent?(ir)).to be false
      end
    end
  end
end
