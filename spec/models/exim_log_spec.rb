require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe EximLog do
    describe ".load_file" do
        it "loads relevant lines of an uncompressed exim log file" do
            Configuration.stub!(:incoming_email_domain).and_return("example.com")
            File.stub_chain(:stat, :mtime).and_return(Date.new(2012, 10, 10))
            log = [
                "This is a line of a logfile relevant to foi+request-1234@example.com",
                "This is the second line for the same foi+request-1234@example.com email address"
            ]
            File.should_receive(:open).with("/var/log/exim4/exim-mainlog-2012-10-10", "r").and_return(log)
            ir = info_requests(:fancy_dog_request)
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
            File.stub_chain(:stat, :mtime).and_return(DateTime.new(2012, 10, 10))
            File.should_receive(:open).with("/var/log/exim4/exim-mainlog-2012-10-10", "r").once.and_return([])

            EximLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
            EximLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
        end

        it "loads the log file again if it's changed" do
            File.should_receive(:open).with("/var/log/exim4/exim-mainlog-2012-10-10", "r").twice.and_return([])
            File.stub_chain(:stat, :mtime).and_return(DateTime.new(2012, 10, 10))
            EximLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
            File.stub_chain(:stat, :mtime).and_return(DateTime.new(2012, 10, 11))
            EximLog.load_file("/var/log/exim4/exim-mainlog-2012-10-10")
        end
    end
end
