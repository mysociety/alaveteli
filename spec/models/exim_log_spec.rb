require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe EximLog do
    describe ".load_file" do
        before :each do
            Configuration.stub!(:incoming_email_domain).and_return("example.com")
            File.stub_chain(:stat, :mtime).and_return(DateTime.new(2012, 10, 10))
        end

        let(:log) {[
            "This is a line of a logfile relevant to foi+request-1234@example.com",
            "This is the second line for the same foi+request-1234@example.com email address"
        ]}

        let(:ir) { info_requests(:fancy_dog_request) }

        it "loads relevant lines of an uncompressed exim log file" do
            File.should_receive(:open).with("/var/log/exim4/exim-mainlog-2012-10-10", "r").and_return(log)
            InfoRequest.should_receive(:find_by_incoming_email).with("request-1234@example.com").twice.and_return(ir)
            EximLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")

            ir.exim_logs.count.should == 2
            log = ir.exim_logs[0]
            log.order.should == 1
            log.line.should == "This is a line of a logfile relevant to foi+request-1234@example.com"

            log = ir.exim_logs[1]
            log.order.should == 2
            log.line.should == "This is the second line for the same foi+request-1234@example.com email address"
        end

        it "doesn't load the log file twice if it's unchanged" do
            File.should_receive(:open).with("/var/log/exim4/exim-mainlog-2012-10-10", "r").once.and_return([])

            EximLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
            EximLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
        end

        it "loads the log file again if it's changed" do
            File.should_receive(:open).with("/var/log/exim4/exim-mainlog-2012-10-10", "r").twice.and_return([])
            EximLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
            File.stub_chain(:stat, :mtime).and_return(DateTime.new(2012, 10, 11))
            EximLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
        end

        it "doesn't end up with two copies of each line when the same file is actually loaded twice" do
            File.should_receive(:open).with("/var/log/exim4/exim-mainlog-2012-10-10", "r").twice.and_return(log)
            InfoRequest.should_receive(:find_by_incoming_email).with("request-1234@example.com").any_number_of_times.and_return(ir)

            EximLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
            ir.exim_logs.count.should == 2

            File.stub_chain(:stat, :mtime).and_return(DateTime.new(2012, 10, 11))
            EximLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
            ir.exim_logs.count.should == 2
        end

        it "easily handles gzip compress log files" do
            File.should_not_receive(:open)
            Zlib::GzipReader.should_receive(:open).with("/var/log/exim4/exim-mainlog-2012-10-10.gz").and_return([])
            EximLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10.gz")
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
                Configuration.stub!(:incoming_email_domain).and_return("example.com")
                log.stub!(:rewind)
                ir1 = info_requests(:fancy_dog_request)
                ir2 = info_requests(:naughty_chicken_request)
                InfoRequest.should_receive(:find_by_incoming_email).with("request-14-e0e09f97@example.com").any_number_of_times.and_return(ir1)
                InfoRequest.should_receive(:find_by_incoming_email).with("request-10-1234@example.com").any_number_of_times.and_return(ir2)
                EximLog.load_postfix_log_data(log, EximLogDone.new(:filename => "foo", :last_stat => DateTime.now))
                # TODO: Check that each log line is attached to the correct request
                ir1.exim_logs.count.should == 5
                ir1.exim_logs[0].order.should == 1
                ir1.exim_logs[0].line.should == "Oct  3 16:39:35 host postfix/pickup[2257]: CB55836EE58C: uid=1003 from=<foitest+request-14-e0e09f97@example.com>"
                ir1.exim_logs[1].order.should == 2
                ir1.exim_logs[1].line.should == "Oct  3 16:39:35 host postfix/cleanup[7674]: CB55836EE58C: message-id=<ogm-15+506bdda7a4551-20ee@example.com>"
                ir1.exim_logs[2].order.should == 4
                ir1.exim_logs[2].line.should == "Oct  3 16:39:35 host postfix/qmgr[15615]: CB55836EE58C: from=<foitest+request-14-e0e09f97@example.com>, size=1695, nrcpt=1 (queue active)"
                ir1.exim_logs[3].order.should == 5
                ir1.exim_logs[3].line.should == "Oct  3 16:39:38 host postfix/smtp[7676]: CB55836EE58C: to=<foi@some.gov.au>, relay=aspmx.l.google.com[74.125.25.27]:25, delay=2.5, delays=0.13/0.02/1.7/0.59, dsn=2.0.0, status=sent (250 2.0.0 OK 1349246383 j9si1676296paw.328)"
                ir1.exim_logs[4].order.should == 7
                ir1.exim_logs[4].line.should == "Oct  3 16:39:38 host postfix/qmgr[15615]: CB55836EE58C: removed"
                ir2.exim_logs.count.should == 2
                ir2.exim_logs[0].order.should == 3
                ir2.exim_logs[0].line.should == "Oct  3 16:39:35 host postfix/qmgr[1673]: 9634B16F7F7: from=<foitest+request-10-1234@example.com>, size=368, nrcpt=1 (queue active)"
                ir2.exim_logs[1].order.should == 6
                ir2.exim_logs[1].line.should == "Oct  3 16:39:38 host postfix/smtp[1681]: 9634B16F7F7: to=<kdent@example.com>, relay=none, delay=46, status=deferred (connect to 216.150.150.131[216.150.150.131]: No route to host)"
            end
        end

        describe ".scan_for_postfix_queue_ids" do
            it "returns the queue ids of interest with the connected email addresses" do
                Configuration.stub!(:incoming_email_domain).and_return("example.com")
                EximLog.scan_for_postfix_queue_ids(log).should == {
                    "CB55836EE58C" => ["request-14-e0e09f97@example.com"],
                    "9634B16F7F7" => ["request-10-1234@example.com"]
                }
            end
        end

        describe ".extract_postfix_queue_id_from_syslog_line" do
            it "returns nil if there is no queue id" do                
                EximLog.extract_postfix_queue_id_from_syslog_line("Oct  7 07:16:48 kedumba postfix/smtp[14294]: connect to mail.neilcopp.com.au[110.142.151.66]:25: Connection refused").should be_nil
            end
        end
    end
end
