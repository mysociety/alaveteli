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
end
