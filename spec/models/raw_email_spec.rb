# == Schema Information
#
# Table name: raw_emails
#
#  id :integer          not null, primary key
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User, "manipulating a raw email" do

    before do
        @raw_email = RawEmail.new
        incoming_message = mock_model(IncomingMessage)
        info_request = mock_model(InfoRequest)
        incoming_message.stub!(:info_request).and_return(info_request)
        @raw_email.stub!(:incoming_message).and_return(incoming_message)
    end

    it 'putting data in comes back out' do
        @raw_email.data = "Hello, world!"
        @raw_email.save!
        @raw_email.reload
        @raw_email.data.should == "Hello, world!"
    end

end

