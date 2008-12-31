require File.dirname(__FILE__) + '/../spec_helper'

describe InfoRequest, " when emailing" do
    fixtures :info_requests, :info_request_events, :public_bodies, :users

    before do
        @info_request = info_requests(:fancy_dog_request)
    end

    it "should have a valid incoming email" do
        @info_request.incoming_email.should_not be_nil
    end

    it "should recognise its own incoming email" do
        incoming_email = @info_request.incoming_email
        found_info_request = InfoRequest.find_by_incoming_email(incoming_email)
        found_info_request.should == (@info_request)
    end

    it "should recognise its own incoming email with some capitalisation" do
        incoming_email = @info_request.incoming_email.gsub(/request/, "Request")
        found_info_request = InfoRequest.find_by_incoming_email(incoming_email)
        found_info_request.should == (@info_request)
    end

    it "should recognise its own incoming email with quotes" do
        incoming_email = "'" + @info_request.incoming_email + "'"
        found_info_request = InfoRequest.find_by_incoming_email(incoming_email)
        found_info_request.should == (@info_request)
    end

    it "should recognise l and 1 as the same in incoming emails" do
        # Make info request with a 1 in it
        while true
            ir = InfoRequest.new(:title => "testing", :public_body => public_bodies(:geraldine_public_body),
                :user => users(:bob_smith_user))
            ir.save!
            hash_part = ir.incoming_email.match(/-[0-9a-f]+@/)[0]
            break if hash_part.match(/1/)
        end
        
        # Make email with a 1 in the hash part changed to l
        test_email = ir.incoming_email
        new_hash_part = hash_part.gsub(/1/, "l")
        test_email.gsub!(hash_part, new_hash_part)

        # Try and find with an l
        found_info_request = InfoRequest.find_by_incoming_email(test_email)
        found_info_request.should == (ir)
    end

    it "should recognise old style request-bounce- addresses" do
        incoming_email = @info_request.magic_email("request-bounce-")
        found_info_request = InfoRequest.find_by_incoming_email(incoming_email)
        found_info_request.should == (@info_request)
    end

    it "should return nil when receiving email for a deleted request" do
        deleted_request_address = InfoRequest.magic_email_for_id("request-", 98765)  
        found_info_request = InfoRequest.find_by_incoming_email(deleted_request_address)
        found_info_request.should be_nil
    end

    it "should cope with indexing after item is deleted" do
        # check can just update index
        info_request_events(:useless_incoming_message_event).save!
        ActsAsXapian.update_index(false, true)

        # then delete it under it
        info_request_events(:useless_incoming_message_event).save!
        info_request_events(:useless_incoming_message_event).destroy
        ActsAsXapian.update_index(false, true)

       # raise ActsAsXapian::ActsAsXapianJob.find(:all).to_yaml
    end

end


