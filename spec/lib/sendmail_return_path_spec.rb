# This is a test of the monkey patches in sendmail_return_path.rb

require File.dirname(__FILE__) + '/../spec_helper'

describe "when sending email with an altered return path" do

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
        mock_smtp_session.should_receive(:sendmail).once.with(anything(), ["test@localhost"], anything())

        Net::SMTP.stub!(:new).and_return(mock_smtp)

        with_delivery_method :smtp do
            ContactMailer.deliver_message(
                "Mr. Test", "test@localhost", "Test script spec/lib/sendmail_return_path_spec.rb",
                "This is just a test for a test script", nil, nil, nil
            )
        end
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
    # Replace it entirely with a dummy function that just returns nil, so we can stub it.
    def with_stub_popen()
        old_popen = IO.method(:popen).unbind
        IO.class_eval "def self.popen(a, b); nil; end"
        yield
    ensure
        old_popen.bind(IO)
    end


end


