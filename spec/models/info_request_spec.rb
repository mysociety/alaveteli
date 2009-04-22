require File.dirname(__FILE__) + '/../spec_helper'

describe InfoRequest do 
    
    describe "when asked for the last event id that needs description" do 
    
        before do
            @info_request = InfoRequest.new
        end
        
        it 'should return the last undescribed event id if there is one' do 
            last_mock_event = mock_model(InfoRequestEvent)
            other_mock_event = mock_model(InfoRequestEvent)
            @info_request.stub!(:events_needing_description).and_return([other_mock_event, last_mock_event])
            @info_request.last_event_id_needing_description.should == last_mock_event.id
        end 
        
        it 'should return zero if there are no undescribed events' do
            @info_request.stub!(:events_needing_description).and_return([])
            @info_request.last_event_id_needing_description.should == 0
        end
        
    end
    
    describe " when emailing" do
    
        fixtures :info_requests, :info_request_events, :public_bodies, :users

        before do
            @info_request = info_requests(:fancy_dog_request)
        end

        it "should have a valid incoming email" do
            @info_request.incoming_email.should_not be_nil
        end

        it "should have a sensible incoming name and email" do
            @info_request.incoming_name_and_email.should == "Bob Smith <" + @info_request.incoming_email + ">"
        end

        it "should have a sensible recipient name and email" do
            @info_request.recipient_name_and_email.should == "FOI requests at TGQ <geraldine-requests@localhost>"
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
            rebuild_xapian_index
            verbose = false

            # delete event from underneath indexing; shouldn't cause error
            info_request_events(:useless_incoming_message_event).save!
            info_request_events(:useless_incoming_message_event).destroy
            ActsAsXapian.update_index(true, verbose)
        end

    end 

    describe "when calculating the status" do
        fixtures :info_requests, :info_request_events, :holidays

        before do
            @ir = info_requests(:naughty_chicken_request)
        end

        it "has correct due date" do
            @ir.date_response_required_by.strftime("%F").should == '2007-11-12'
        end

        it "isn't overdue on due date" do
            Time.stub!(:now).and_return(Time.utc(2007, 11, 12, 23, 59)) 
            @ir.calculate_status.should == 'waiting_response'
        end

        it "is overdue a day after due date " do
            Time.stub!(:now).and_return(Time.utc(2007, 11, 13)) 
            @ir.calculate_status.should == 'waiting_response_overdue'
        end
    end
    
    describe 'when asked if a user is the owning user for this request' do 
    
        before do 
            @mock_user = mock_model(User)
            @info_request = InfoRequest.new(:user => @mock_user)
            @other_mock_user = mock_model(User)
        end
        
        it 'should return false if a nil object is passed to it' do 
            @info_request.is_owning_user?(nil).should be_false
        end
        
        it 'should return true if the user is the request\'s owner' do 
            @info_request.is_owning_user?(@mock_user).should be_true
        end
        
        it 'should return false for a user that is not the owner and does not own every request' do 
            @other_mock_user.stub!(:owns_every_request?).and_return(false)
            @info_request.is_owning_user?(@other_mock_user).should be_false
        end
        
        it 'should return true if the user is not the owner but owns every request' do
            @other_mock_user.stub!(:owns_every_request?).and_return(true)
            @info_request.is_owning_user?(@other_mock_user).should be_true
        end
        
    end
    

    describe 'when asked if it requires admin' do 
    
        before do 
            @info_request = InfoRequest.new
        end
        
        it 'should return true if its described state is error_message' do 
            @info_request.described_state = 'error_message'
            @info_request.requires_admin?.should be_true
        end
        
        it 'should return true if its described state is requires_admin' do 
            @info_request.described_state = 'requires_admin'
            @info_request.requires_admin?.should be_true
        end
        
        it 'should return false if its described state is waiting_response' do 
            @info_request.described_state = 'waiting_response'
            @info_request.requires_admin?.should be_false
        end
        
    end
    
    describe 'when asked for old unclassified requests' do 
    
        before do 
            Time.stub!(:now).and_return(Time.utc(2007, 11, 12, 23, 59))
        end
        
        it 'should ask for requests using any limit param supplied' do 
            InfoRequest.should_receive(:find).with(:all, {:select => anything, 
                                                          :order => anything, 
                                                          :conditions=> anything, 
                                                          :limit => 5})
            InfoRequest.find_old_unclassified(:limit => 5)
        end
        
        it 'should not limit the number of requests returned by default' do 
            InfoRequest.should_not_receive(:find).with(:all, {:select => anything, 
                                                              :order => anything, 
                                                              :conditions=> anything, 
                                                              :limit => anything})
            InfoRequest.find_old_unclassified
        end 
        
        it 'should add extra conditions if supplied' do 
            InfoRequest.should_receive(:find).with(:all, 
                  {:select=> anything, 
                   :order=> anything, 
                   :conditions=>["awaiting_description = ? and (select created_at from info_request_events where info_request_events.info_request_id = info_requests.id and info_request_events.event_type = 'response' order by created_at desc limit 1) < ? and url_title != 'holding_pen' and prominence != 'backpage'", 
                    true, Time.now - 14.days]})
            InfoRequest.find_old_unclassified({:conditions => ["prominence != 'backpage'"]})
        end
        
        it 'should ask the database for requests that are awaiting description, have a last response older than 14 days old, are not the holding pen and are not backpaged' do 
            InfoRequest.should_receive(:find).with(:all, 
                  {:select=>"*, (select created_at from info_request_events where info_request_events.info_request_id = info_requests.id and info_request_events.event_type = 'response' order by created_at desc limit 1) as last_response_time", 
                   :order=>"last_response_time", 
                   :conditions=>["awaiting_description = ? and (select created_at from info_request_events where info_request_events.info_request_id = info_requests.id and info_request_events.event_type = 'response' order by created_at desc limit 1) < ? and url_title != 'holding_pen'", 
                    true, Time.now - 14.days]})
            InfoRequest.find_old_unclassified
        end
        
    end
    
    describe 'when an instance is asked if it is old and unclassified' do 
        
        before do 
            Time.stub!(:now).and_return(Time.utc(2007, 11, 12, 23, 59))
            @mock_comment_event = mock_model(InfoRequestEvent, :created_at => Time.now - 16.days, :event_type => 'comment')
            @mock_response_event = mock_model(InfoRequestEvent, :created_at => Time.now - 15.days, :event_type => 'response')
            @info_request = InfoRequest.new(:prominence => 'normal', 
                                            :awaiting_description => true, 
                                            :info_request_events => [@mock_response_event, @mock_comment_event])
        end
        
        it 'should return false if it is the holding pen' do 
            @info_request.stub!(:url_title).and_return('holding_pen')
            @info_request.is_old_unclassified?.should be_false
        end
        
        it 'should return false if it is not awaiting description' do 
            @info_request.stub!(:awaiting_description).and_return(false)
            @info_request.is_old_unclassified?.should be_false
        end
        
        it 'should return false if its last response event occurred less than 14 days ago' do 
            @mock_response_event.stub!(:created_at).and_return(Time.now - 13.days)
            @info_request.is_old_unclassified?.should be_false
        end
        
        it 'should return true if it is awaiting description, isn\'t the holding pen and hasn\'t had an event in 14 days' do 
            @info_request.is_old_unclassified?.should be_true
        end
        
    end
    
end
