require File.dirname(__FILE__) + '/../spec_helper'

describe User, "manipulating a raw email" do 
    before do
        @raw_email = RawEmail.new
    end

    it 'putting data in comes back out' do 
        @raw_email.data = "Hello, world!"
        @raw_email.save!
        @raw_email.reload
        @raw_email.data.should == "Hello, world!"
    end

    it 'putting data in comes back out even if it has a backslash in it' do 
        @raw_email.data = "This \\ that"
        @raw_email.save!
        @raw_email.reload
        STDERR.puts @raw_email.data
        STDERR.puts "This \\ that"
        @raw_email.data.should == "This \\ that"
    end

end
 
