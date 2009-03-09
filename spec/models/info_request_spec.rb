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
        verbose = false

        # check can just update index
        info_request_events(:useless_incoming_message_event).save!
        ActsAsXapian.update_index(false, verbose)

        # then delete it under it
        info_request_events(:useless_incoming_message_event).save!
        info_request_events(:useless_incoming_message_event).destroy
        ActsAsXapian.update_index(false, verbose)

       # raise ActsAsXapian::ActsAsXapianJob.find(:all).to_yaml
    end

end 

describe InfoRequest, " when calculating due date" do
    fixtures :info_requests, :info_request_events, :public_bodies, :users

    before do
        @ir = info_requests(:fancy_dog_request)
    end

    it "knows when it needs answered by" do
        @ir.date_response_required_by.strftime("%F").should == '2007-11-22'
    end

    # These ones should all move when the underlying method moves
    # I'm not sure what the best way is in RSpec to do this sort of data
    # driven test so that it reports which one is failing rather than
    # breaking out on first failure

    test_dates = {
        'no_holidays'   => ['2008-10-01' , '2008-10-29' ],
        'not_leap_year' => ['2007-02-01' , '2007-03-01' ],
        'leap_year'     => ['2008-02-01' , '2008-02-29' ],
        'on_thu'        => ['2009-03-12' , '2009-04-14' ],
        'on_fri'        => ['2009-03-13' , '2009-04-15' ],
        'on_sat'        => ['2009-03-14' , '2009-04-16' ],
        'on_sun'        => ['2009-03-15' , '2009-04-16' ],
        'on_mon'        => ['2009-03-16' , '2009-04-16' ],
    }

    it "gets it right" do
        test_dates.each_pair do |name, date|
            reqdate = Date.strptime(date[0])
            @ir.due_date_for_request_date(reqdate).strftime("%F").should == date[1]
        end
    end

end

describe InfoRequest, "when calculating status" do
    fixtures :public_bodies, :users

    # We can't use fixtures as we need to control the date of a message
    # See due_date_for_request_date tests for fine grained testing

    def send_msg(date)
        ir = InfoRequest.new(:title => "testing", :public_body => public_bodies(:geraldine_public_body),
             :user => users(:bob_smith_user))
        ir.save!
        om = OutgoingMessage.new( 
            :info_request_id => ir.id, 
            :last_sent_at => date,
            :body => '...',
            :status => 'sent',
            :message_type => 'initial_request',
            :what_doing => 'new_information'
        )
        om.save!
        e = InfoRequestEvent.new( 
            :event_type => 'sent', 
            :info_request_id => ir.id, 
            :outgoing_message_id => om.id,
            :params_yaml => { :outgoing_message_id => om.id }.to_yaml
        )
        e.save!
        return ir
    end

    it "is awaiting response when recently new" do
        ir = send_msg(Time.new - 5.days)
        ir.calculate_status.should == 'waiting_response'
    end 

    it "is overdue when very old" do
        ir = send_msg(Time.new - 50.days)
        ir.calculate_status.should == 'waiting_response_overdue'
    end 

end

