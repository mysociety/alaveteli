# -*- encoding : utf-8 -*-
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

    # TODO: this test fails, hopefully will be fixed in later Rails.
    # Doesn't matter too much for us for storing raw_emails, it would seem,
    # but keep an eye out.

    # This is testing a bug in Rails PostgreSQL code
    # http://blog.aradine.com/2009/09/rubys-marshal-and-activerecord-and.html
    # https://rails.lighthouseapp.com/projects/8994/tickets/1063-binary-data-broken-with-postgresql-adapter
#    it 'putting data in comes back out even if it has a backslash in it' do 
#        @raw_email.data = "This \\ that"
#        @raw_email.save!
#        @raw_email.reload
#        $stderr.puts @raw_email.data
#        $stderr.puts "This \\ that"
#        @raw_email.data.should == "This \\ that"
#    end

end
 
