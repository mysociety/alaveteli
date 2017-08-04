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
#  delivery_status         :string(255)
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MailServerLog do
  describe ".load_file" do
    before :each do
      allow(AlaveteliConfiguration).to receive(:incoming_email_domain).and_return("example.com")
      allow(AlaveteliConfiguration).to receive(:incoming_email_prefix).and_return('foi+')
      allow(File).to receive_message_chain(:stat, :mtime).and_return(DateTime.new(2012, 10, 10))
    end

    let(:text_log_path) { file_fixture_name('exim-mainlog-2012-10-10') }
    let(:gzip_log_path) { file_fixture_name('exim-mainlog-2012-10-10.gz') }
    let(:ir) { info_requests(:fancy_dog_request) }

    it "loads relevant lines of an uncompressed exim log file" do
      expect(InfoRequest).to receive(:find_by_incoming_email).with("foi+request-1234@example.com").twice.and_return(ir)
      MailServerLog.load_file(text_log_path)

      expect(ir.mail_server_logs.count).to eq(2)
      log = ir.mail_server_logs[0]
      expect(log.order).to eq(1)
      expect(log.line).to eq("This is a line of a logfile relevant to foi+request-1234@example.com\n")

      log = ir.mail_server_logs[1]
      expect(log.order).to eq(2)
      expect(log.line).to eq("This is the second line for the same foi+request-1234@example.com email address\n")
    end

    it "doesn't load the log file twice if it's unchanged" do
      File.open(text_log_path, 'r') do |file|
        expect(File).to receive(:open).with(text_log_path, 'r').once.and_return(file)
        expect(InfoRequest).to receive(:find_by_incoming_email).with("foi+request-1234@example.com").twice.and_return(ir)
        MailServerLog.load_file(text_log_path)
        MailServerLog.load_file(text_log_path)
      end
    end

    it "loads the log file again if it's changed" do
      expect(File).to receive(:open).with(text_log_path, 'r').twice.and_call_original
      expect(InfoRequest).to receive(:find_by_incoming_email).with("foi+request-1234@example.com").exactly(4).times.and_return(ir)
      MailServerLog.load_file(text_log_path)
      allow(File).to receive_message_chain(:stat, :mtime).and_return(DateTime.new(2012, 10, 11))
      MailServerLog.load_file(text_log_path)
    end

    it "doesn't end up with two copies of each line when the same file is actually loaded twice" do
      allow(InfoRequest).to receive(:find_by_incoming_email).with("foi+request-1234@example.com").and_return(ir)

      MailServerLog.load_file(text_log_path)
      expect(ir.mail_server_logs.count).to eq(2)

      allow(File).to receive_message_chain(:stat, :mtime).and_return(DateTime.new(2012, 10, 11))
      MailServerLog.load_file(text_log_path)
      expect(ir.mail_server_logs.count).to eq(2)
    end

    it "easily handles gzip compress log files" do
      allow(InfoRequest).to receive(:find_by_incoming_email).with("foi+request-1234@example.com").and_return(ir)

      MailServerLog.load_file(gzip_log_path)

      log = ir.mail_server_logs.first
      expect(log.line).to eq("This is a line of a logfile relevant to foi+request-1234@example.com\n")
    end

    context "there is a delivery status" do
      it "stores the delivery status" do
        allow(InfoRequest).to receive(:find_by_incoming_email).
          with("foi+request-1234@example.com").and_return(ir)
        MailServerLog.load_file(file_fixture_name('exim-mainlog-2016-04-28'))
        expect(ir.mail_server_logs[0].attributes['delivery_status']).
          to eq(MailServerLog::DeliveryStatus.new(:sent))
      end
    end

    context "there is no delivery status" do
      it "stores the delivery status" do
        allow(InfoRequest).to receive(:find_by_incoming_email).
          with("foi+request-1234@example.com").and_return(ir)
        MailServerLog.load_file(text_log_path)
        expect(ir.mail_server_logs[0].attributes).
          to_not include(['delivery_status'])
      end
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
      expect(MailServerLog.email_addresses_on_line("unknown+request-14-e0e09f97@example.com")).to be_empty
    end

    it "ignores an email where the . is substituted for something else" do
      expect(MailServerLog.email_addresses_on_line("foi+request-14-e0e09f97@exampledcom")).to be_empty
    end
  end

  context "Exim" do
    describe ".load_exim_log_data" do
      it "sanitizes each line in the log file" do
        allow(AlaveteliConfiguration).to receive(:incoming_email_domain).and_return("example.com")
        allow(AlaveteliConfiguration).to receive(:incoming_email_prefix).and_return("foi+")

        ir = info_requests(:fancy_dog_request)
        allow(InfoRequest).to receive(:find_by_incoming_email).with("foi+request-1234@example.com").and_return(ir)

        # Log files can contain stuff which isn't valid UTF-8 sometimes when
        # things go wrong.
        fixture_path = file_fixture_name('exim-bad-utf8-exim-log')
        log = File.open(fixture_path, 'r')
        done = MailServerLogDone.new(:filename => "foo",
                                     :last_stat => DateTime.new(2012, 10, 10))

        expect(ir.mail_server_logs.count).to eq 0
        # This will error if we don't sanitize the lines
        MailServerLog.load_exim_log_data(log, done)
        expect(ir.mail_server_logs.count).to eq 3

        # Check that we stored a sanitised version of the log line
        expected_log_line = "2015-07-09 15:41:40 [29933] foi+request-1234" \
                            "@example.com SMTP protocol synchronization " \
                            "error (next input sent too soon: pipelining was" \
                            " not advertised): rejected \"EHLO 0]C\u000E" \
                            "\u000E\u0003\u001C<\u0006\u0019~\u0006|='" \
                            "\u0016)\u0006\u0005\" H=remote.comagex.be " \
                            "[91.183.116.119]:53191 I=[46.43.39.78]:25 " \
                            "next \input=\"\\f\\227\\212\\016\\314\\246" \
                            "\\r\\n\"\n"
        expect(ir.mail_server_logs[1].line).to eq expected_log_line
        log.close
      end
    end

    describe '.request_exim_sent?' do

      it "returns true when a log line says the message was sent" do
        line = "Apr 28 15:53:37 server exim[12105]: 2016-04-28 15:53:37 " \
               "[12105] 1avnJx-00039F-Hs <= " \
               "foi+request-331612-13811a2b@example.com U=foi P=local " \
               "S=1986 id=ogm-538593+572f16e888-166a@example.com " \
               "T=\"Freedom of Information request - example request\" " \
               "from <foi+request-331612-13811a2b@example.com> for " \
               "foi@example.org foi@example.org"
        info_request = FactoryGirl.create(:info_request)
        allow(info_request).to receive(:incoming_email).
          and_return('foi+request-331612-13811a2b@example.com')
        info_request.mail_server_logs.create!(:line => line, :order => 1)
        expect(MailServerLog.request_exim_sent?(info_request)).to be true
      end

      it 'returns false if a log of delivery has a different
          envelope sender' do
        line = "Apr 28 15:53:37 server exim[12105]: 2016-04-28 15:53:37 " \
               "[12105] 1avnJx-00039F-Hs <= " \
               "foi+request-331612-13811a2b@example.com U=foi P=local " \
               "S=1986 id=ogm-538593+572f16e888-166a@example.com " \
               "T=\"Freedom of Information request - example request\" " \
               "from <alaveteli@example.com> for " \
               "foi@example.org foi@example.org"
        info_request = FactoryGirl.create(:info_request)
        allow(info_request).to receive(:incoming_email).
          and_return('foi+request-331612-13811a2b@example.com')
        info_request.mail_server_logs.create!(:line => line, :order => 1)
        expect(MailServerLog.request_exim_sent?(info_request)).to be false
      end

      it "returns false when no log lines say the message has been sent" do
        info_request = FactoryGirl.create(:info_request)
        expect(MailServerLog.request_exim_sent?(info_request)).to be false
      end
    end

  end

  context "Postfix" do
    let(:log) {[
      "Oct  3 16:39:35 host postfix/pickup[2257]: CB55836EE58C: uid=1003 from=<foi+request-14-e0e09f97@example.com>",
      "Oct  3 16:39:35 host postfix/cleanup[7674]: CB55836EE58C: message-id=<ogm-15+506bdda7a4551-20ee@example.com>",
      "Oct  3 16:39:35 host postfix/qmgr[1673]: 9634B16F7F7: from=<foi+request-10-1234@example.com>, size=368, nrcpt=1 (queue active)",
      "Oct  3 16:39:35 host postfix/qmgr[15615]: CB55836EE58C: from=<foi+request-14-e0e09f97@example.com>, size=1695, nrcpt=1 (queue active)",
      "Oct  3 16:39:38 host postfix/smtp[7676]: CB55836EE58C: to=<foi@some.gov.au>, relay=aspmx.l.google.com[74.125.25.27]:25, delay=2.5, delays=0.13/0.02/1.7/0.59, dsn=2.0.0, status=sent (250 2.0.0 OK 1349246383 j9si1676296paw.328)",
      "Oct  3 16:39:38 host postfix/smtp[1681]: 9634B16F7F7: to=<kdent@example.com>, relay=none, delay=46, status=deferred (connect to 216.150.150.131[216.150.150.131]: No route to host)",
      "Oct  3 16:39:38 host postfix/qmgr[15615]: CB55836EE58C: removed",
    ]}

    describe ".load_postfix_log_data" do
      # Postfix logs for a single email go over multiple lines. They are all tied together with the Queue ID.
      # See http://onlamp.com/onlamp/2004/01/22/postfix.html
      it "loads the postfix log and untangles seperate email transactions using the queue ID" do
        allow(AlaveteliConfiguration).to receive(:incoming_email_domain).and_return("example.com")
        allow(AlaveteliConfiguration).to receive(:incoming_email_prefix).and_return("foi+")
        allow(log).to receive(:rewind)
        ir1 = info_requests(:fancy_dog_request)
        ir2 = info_requests(:naughty_chicken_request)
        allow(InfoRequest).to receive(:find_by_incoming_email).with("foi+request-14-e0e09f97@example.com").and_return(ir1)
        allow(InfoRequest).to receive(:find_by_incoming_email).with("foi+request-10-1234@example.com").and_return(ir2)
        MailServerLog.load_postfix_log_data(log, MailServerLogDone.new(:filename => "foo", :last_stat => Time.zone.now))
        # TODO: Check that each log line is attached to the correct request
        expect(ir1.mail_server_logs.count).to eq(5)
        expect(ir1.mail_server_logs[0].order).to eq(1)
        expect(ir1.mail_server_logs[0].line).to eq("Oct  3 16:39:35 host postfix/pickup[2257]: CB55836EE58C: uid=1003 from=<foi+request-14-e0e09f97@example.com>")
        expect(ir1.mail_server_logs[1].order).to eq(2)
        expect(ir1.mail_server_logs[1].line).to eq("Oct  3 16:39:35 host postfix/cleanup[7674]: CB55836EE58C: message-id=<ogm-15+506bdda7a4551-20ee@example.com>")
        expect(ir1.mail_server_logs[2].order).to eq(4)
        expect(ir1.mail_server_logs[2].line).to eq("Oct  3 16:39:35 host postfix/qmgr[15615]: CB55836EE58C: from=<foi+request-14-e0e09f97@example.com>, size=1695, nrcpt=1 (queue active)")
        expect(ir1.mail_server_logs[3].order).to eq(5)
        expect(ir1.mail_server_logs[3].line).to eq("Oct  3 16:39:38 host postfix/smtp[7676]: CB55836EE58C: to=<foi@some.gov.au>, relay=aspmx.l.google.com[74.125.25.27]:25, delay=2.5, delays=0.13/0.02/1.7/0.59, dsn=2.0.0, status=sent (250 2.0.0 OK 1349246383 j9si1676296paw.328)")
        expect(ir1.mail_server_logs[4].order).to eq(7)
        expect(ir1.mail_server_logs[4].line).to eq("Oct  3 16:39:38 host postfix/qmgr[15615]: CB55836EE58C: removed")
        expect(ir2.mail_server_logs.count).to eq(2)
        expect(ir2.mail_server_logs[0].order).to eq(3)
        expect(ir2.mail_server_logs[0].line).to eq("Oct  3 16:39:35 host postfix/qmgr[1673]: 9634B16F7F7: from=<foi+request-10-1234@example.com>, size=368, nrcpt=1 (queue active)")
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

  describe '#line' do

    it 'returns the line attribute' do
      log = MailServerLog.new(:line => 'log line')
      expect(log.line).to eq('log line')
    end

    context ':decorate option is truthy' do

      context 'using the :exim MTA' do

        it 'returns an EximLine containing the line attribute' do
          log = MailServerLog.new(:line => 'log line')
          expect(log.line(:decorate => true)).
            to eq(MailServerLog::EximLine.new('log line'))
        end

      end

      context 'using the :postfix MTA' do

        before do
          allow(AlaveteliConfiguration).to receive(:mta_log_type).and_return('postfix')
        end

        it 'returns a PostfixLine containing the line attribute' do
          log = MailServerLog.new(:line => 'log line')
          expect(log.line(:decorate => true)).
            to eq(MailServerLog::PostfixLine.new('log line'))
        end

      end

    end

    context ':redact option is truthy' do

      it 'redacts the info request id hash' do
        log = FactoryGirl.create(:mail_server_log)
        line = log.line += " #{ log.info_request.incoming_email }"
        idhash = log.info_request.idhash
        log.update_attributes!(:line => line)
        expect(log.line(:redact => true)).to_not include(idhash)
      end

      it 'redacts the info request id when decorated' do
        log = FactoryGirl.create(:mail_server_log)
        line = log.line += " #{ log.info_request.incoming_email }"
        idhash = log.info_request.idhash
        log.update_attributes!(:line => line)
        expect(log.line(:redact => true, :decorate => true).to_s).
          to_not include(idhash)
      end

      it 'handles not having an associated info request' do
        log = MailServerLog.new(:line => 'log line')
        expect(log.line(:redact => true)).to eq('log line')
      end

      it 'handles the info request not having an idhash' do
        request = FactoryGirl.build(:info_request)
        log = MailServerLog.new(:line => 'log line', :info_request => request)
        expect(log.line(:redact => true)).to eq('log line')
      end

      it 'redacts the hostname if the router is sent_to_smarthost' do
        log = MailServerLog.new(:line => <<-EOF.squish)
        R=send_to_smarthost
        H=secret.ukcod.org.uk [127.0.0.1]:25
        EOF
        redacted = log.line(:redact => true)
        expect(redacted).to match(/H\=\[REDACTED\]/)
        expect(redacted).to_not include('secret.ukcod.org.uk [127.0.0.1]:25')
      end

      it 'does not redact the hostname unless the router is sent_to_smarthost' do
        log = MailServerLog.new(:line => <<-EOF.squish)
        R=dnslookup_returnpath_dkim
        H=notsecret.ukcod.org.uk [127.0.0.1]:25
        EOF
        redacted = log.line(:redact => true)
        expect(redacted).to include('secret.ukcod.org.uk [127.0.0.1]:25')
      end

      it 'strips syslog prefixes' do
        log = MailServerLog.new(:line => <<-EOF.squish)
        Jan  1 16:26:57 secret exim[15407]: 2017-01-01 16:26:57
        [15407] 1cNiyG-00040U-Ls => body@example.com…
        EOF

        expect(log.line(:redact => true)).to eq(<<-EOF.squish)
        2017-01-01 16:26:57 [15407] 1cNiyG-00040U-Ls => body@example.com…
        EOF
      end

      it 'strips syslog prefixes when the line ends in a newline' do
        log = MailServerLog.new(:line => <<-EOF.squish)
        Jan  1 16:26:57 secret exim[15407]: 2017-01-01 16:26:57
        [15407] 1cNiyG-00040U-Ls => body@example.com…
        EOF

        log.line += "\n"

        expected =
          "2017-01-01 16:26:57 [15407] 1cNiyG-00040U-Ls => body@example.com…\n"

        expect(log.line(:redact => true)).to eq(expected)
      end
    end
  end

  describe '#delivery_status' do

    context 'if there is a stored value' do
      let(:log) do
        FactoryGirl.create(:mail_server_log, :line => "log text **")
      end

      it 'returns the stored value' do
        status = MailServerLog::DeliveryStatus.new(:failed)
        ActiveRecord::Base.connection.execute <<-EOF
        UPDATE "mail_server_logs"
        SET "delivery_status" = 'failed'
        WHERE "mail_server_logs"."id" = #{log.id}
        EOF
        expect(log.reload.delivery_status).to eq(status)
      end

      it 'does not look at the line text' do
        ActiveRecord::Base.connection.execute <<-EOF
        UPDATE "mail_server_logs"
        SET "delivery_status" = 'failed'
        WHERE "mail_server_logs"."id" = #{log.id}
        EOF
        expect(log).to_not receive(:line)
        log.reload.delivery_status
      end

    end

    # TODO: This can be removed when there are no more cached MTA-specific
    # statuses
    context 'if there is a stored value from an MTA-specific status' do
      let(:log) do
        FactoryGirl.create(:mail_server_log, :line => "log text <=")
      end

      it 'recalculates the value' do
        ActiveRecord::Base.connection.execute <<-EOF
        UPDATE "mail_server_logs"
        SET "delivery_status" = 'message_arrival'
        WHERE "mail_server_logs"."id" = #{log.id}
        EOF
        status = MailServerLog::DeliveryStatus.new(:sent)
        expect(log.reload.delivery_status).to eq(status)
      end

      it 'caches the recalculated value' do
        ActiveRecord::Base.connection.execute <<-EOF
        UPDATE "mail_server_logs"
        SET "delivery_status" = 'message_arrival'
        WHERE "mail_server_logs"."id" = #{log.id}
        EOF

        log.reload.delivery_status

        db_value =
          log.
          reload.
          instance_variable_get('@attributes')['delivery_status'].
          value.to_s
        expect(db_value).to eq('sent')
      end
    end

    context 'there is not a stored value' do

      it 'parses the line text' do
        log = MailServerLog.new(:line => "…<=…")
        expect(log.delivery_status).
          to eq(MailServerLog::DeliveryStatus.new(:sent))
      end

      context 'using the :exim MTA' do
        let(:line) do
          "Apr 28 15:53:37 server exim[12105]: 2016-04-28 15:53:37 " \
          "[12105] 1avnJx-00039F-Hs <= " \
          "foi+request-331612-13811a2b@example.com U=foi P=local " \
          "S=1986 id=ogm-538593+572f16e888-166a@example.com " \
          "T=\"Freedom of Information request - example request\" " \
          "from <foi+request-331612-13811a2b@example.com> for " \
          "foi@example.org foi@example.org"
        end

        it 'returns a delivery status for the log line' do
          log = MailServerLog.new(:line => line)
          status = MailServerLog::DeliveryStatus.new(:sent)
          expect(log.delivery_status).to eq(status)
        end

      end

      context 'using the :postfix MTA' do

        before do
          allow(AlaveteliConfiguration).to receive(:mta_log_type).and_return('postfix')
        end

        let(:line) do
          "Oct 10 16:58:38 kedumba postfix/smtp[26358]: A664436F218D: " \
          "to=<contact@openaustraliafoundation.org.au>, " \
          "relay=aspmx.l.google.com[74.125.25.26]:25, delay=2.7, " \
          "delays=0.16/0.02/1.8/0.67, dsn=2.0.0, " \
          "status=sent (250 2.0.0 OK 1349848723 e6si653316paw.346)"
        end

        it 'returns a delivery status for the log line' do
          log = MailServerLog.new(:line => line)
          status = MailServerLog::DeliveryStatus.new(:delivered)
          expect(log.delivery_status).to eq(status)
        end

      end

    end

  end

  describe '#is_owning_user?' do

    it 'returns true if the user is the owning user of the info request' do
      log = FactoryGirl.build(:mail_server_log)
      request = mock_model(InfoRequest, :is_owning_user? => true)
      allow(log).to receive(:info_request).and_return(request)
      expect(log.is_owning_user?(double(:user))).to eq(true)
    end

    it 'returns false if the user is not the owning user of the info request' do
      log = FactoryGirl.build(:mail_server_log)
      request = mock_model(InfoRequest, :is_owning_user? => false)
      allow(log).to receive(:info_request).and_return(request)
      expect(log.is_owning_user?(double(:user))).to eq(false)
    end

  end

  describe '.check_recent_requests_have_been_sent' do

    context 'if all recent requests have been sent' do

      it 'returns true' do
        info_request = FactoryGirl.create(:info_request,
                                          :created_at => Time.zone.now - 5.days)
        allow(MailServerLog).to receive(:request_sent?).with(info_request).
          and_return(true)
        expect(MailServerLog.check_recent_requests_have_been_sent).to eq(true)
      end

    end

    context 'if a recent request has not been sent' do

      it 'returns false' do
        info_request = FactoryGirl.create(:info_request,
                                          :created_at => Time.zone.now - 5.days)
        allow(MailServerLog).to receive(:request_sent?).with(info_request).
          and_return(false)
        allow($stderr).to receive(:puts)
        expect(MailServerLog.check_recent_requests_have_been_sent).to eq(false)
      end

      it 'outputs a message to stderr' do
        info_request = FactoryGirl.create(:info_request,
                                          :created_at => Time.zone.now - 5.days)
        allow(MailServerLog).to receive(:request_sent?).with(info_request).
          and_return(false)
        expected_message = "failed to find request sending in MTA logs for request " \
                           "id #{info_request.id} #{info_request.url_title} (check " \
                           "envelope from is being set to request address in Ruby, " \
                           "and load-mail-server-logs crontab is working)"
        expect($stderr).to receive(:puts).with(expected_message)
        MailServerLog.check_recent_requests_have_been_sent
      end

    end

  end
end
