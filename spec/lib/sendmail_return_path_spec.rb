# This is a test of the monkey patches in sendmail_return_path.rb

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "when sending email with an altered return path" do
    before(:each) { ActionMailer::Base.deliveries = [] }

    it "should default to delivery method test" do
        ActionMailer::Base.delivery_method.should == :test
    end

    it "should let the helper change the method" do
        with_delivery_method :smtp do
            ActionMailer::Base.delivery_method.should == :smtp
        end
        ActionMailer::Base.delivery_method.should == :test
    end

    # Documentation for fancy mock functions: http://rspec.info/documentation/mocks/message_expectations.html
    it "should set the return path when sending email using SMTP" do
        mock_smtp = mock("smtp")
        mock_smtp_session = mock("smtp_session")

        mock_smtp.should_receive(:start).once.and_yield(mock_smtp_session)
        # the second parameter to the SMTP session is the sender (return path)
        mock_smtp_session.should_receive(:sendmail).once.with(anything(), "test@localhost", anything())

        Net::SMTP.stub!(:new).and_return(mock_smtp)

        with_delivery_method :smtp do
            ContactMailer.deliver_message(
                "Mr. Test", "test@localhost", "Test script spec/lib/sendmail_return_path_spec.rb",
                "This is just a test for a test script", nil, nil, nil
            )
        end

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 0
    end

    it "should set the return path when sending email using sendmail" do
        with_stub_popen do
            IO.should_receive(:popen).once.with('/usr/sbin/sendmail -i -t -f "test@localhost"', "w+")
            with_delivery_method :sendmail do
                ContactMailer.deliver_message(
                    "Mr. Test", "test@localhost", "Test script spec/lib/sendmail_return_path_spec.rb",
                    "This is just a test for a test script", nil, nil, nil
                )
            end
        end

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 0
    end


 protected
    # Change the way Rails delivers memory, just for current scope
    def with_delivery_method(new_delivery_method)
        old_delivery_method, ActionMailer::Base.delivery_method = ActionMailer::Base.delivery_method, new_delivery_method
        yield
    ensure
        ActionMailer::Base.delivery_method = old_delivery_method
    end

    # By default, we can't stub popen, presumably because it is a builtin written in C.
    # Replace it entirely with a normal method that just calls the C one, so we can stub it -
    # this leaves IO working afterwards (for other tests that run in the same instance).
    def with_stub_popen()
        IO.class_eval "@orig_popen = self.method(:popen); def self.popen(a, b, &c); @orig_popen.call(a, b, &c); end"
        begin
            yield
        ensure
            # in theory would undo the popen alterations and return IO to a pristine state, but
            # don't know how to (much fiddling with alias bind and the like didn't help). It
            # doesn't matter - the new popen should behave just the same.
        end
    end


end


