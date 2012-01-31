require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InfoRequest do 

    describe "guessing a request from an email" do 

        before(:each) do
            @im = incoming_messages(:useless_incoming_message)
            load_raw_emails_data
        end

        it 'should compute a hash' do
            @info_request = InfoRequest.new(:title => "testing",
                                            :public_body => public_bodies(:geraldine_public_body),
                                            :user_id => 1)
            @info_request.save!
            @info_request.idhash.should_not == nil
        end

        it 'should find a request based on an email with an intact id and a broken hash' do 
            ir = info_requests(:fancy_dog_request)
            id = ir.id
            @im.mail.to = "request-#{id}-asdfg@example.com"
            guessed = InfoRequest.guess_by_incoming_email(@im)
            guessed[0].idhash.should == ir.idhash
        end

        it 'should find a request based on an email with a broken id and an intact hash' do
            ir = info_requests(:fancy_dog_request)
            idhash = ir.idhash
            @im.mail.to = "request-123ab-#{idhash}@example.com"
            guessed = InfoRequest.guess_by_incoming_email(@im)
            guessed[0].id.should == ir.id
        end

    end

    describe "making up the URL title" do 
        before do
            @info_request = InfoRequest.new
        end

        it 'should remove spaces, and make lower case' do 
            @info_request.title = 'Something True'
            @info_request.url_title.should == 'something_true'
        end

        it 'should not allow a numeric title' do 
            @info_request.title = '1234'
            @info_request.url_title.should == 'request'
        end
    end
     
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
            IncomingMessage.find(:all).each{|x| x.parse_raw_email!}
            rebuild_xapian_index
            # delete event from underneath indexing; shouldn't cause error
            info_request_events(:useless_incoming_message_event).save!
            info_request_events(:useless_incoming_message_event).destroy
            update_xapian_index
        end

    end 

    describe "when calculating the status" do

        before do
            @ir = info_requests(:naughty_chicken_request)
        end

        it "has expected sent date" do
            @ir.last_event_forming_initial_request.outgoing_message.last_sent_at.strftime("%F").should == '2007-10-14'
        end

        it "has correct due date" do
            @ir.date_response_required_by.strftime("%F").should == '2007-11-09'
        end

        it "has correct very overdue after date" do
            @ir.date_very_overdue_after.strftime("%F").should == '2007-12-10'
        end

        it "isn't overdue on due date (20 working days after request sent)" do
            Time.stub!(:now).and_return(Time.utc(2007, 11, 9, 23, 59)) 
            @ir.calculate_status.should == 'waiting_response'
        end

        it "is overdue a day after due date (20 working days after request sent)" do
            Time.stub!(:now).and_return(Time.utc(2007, 11, 10, 00, 01)) 
            @ir.calculate_status.should == 'waiting_response_overdue'
        end

        it "is still overdue 40 working days after request sent" do
            Time.stub!(:now).and_return(Time.utc(2007, 12, 10, 23, 59)) 
            @ir.calculate_status.should == 'waiting_response_overdue'
        end

        it "is very overdue the day after 40 working days after request sent" do
            Time.stub!(:now).and_return(Time.utc(2007, 12, 11, 00, 01)) 
            @ir.calculate_status.should == 'waiting_response_very_overdue'
        end
    end


    describe "when using a plugin and calculating the status" do

        before do
            InfoRequest.send(:require, File.expand_path(File.dirname(__FILE__) + '/customstates'))
            InfoRequest.send(:include, InfoRequestCustomStates)
            InfoRequest.class_eval('@@custom_states_loaded = true')
            @ir = info_requests(:naughty_chicken_request)
        end

        it "rejects invalid states" do
            lambda {@ir.set_described_state("foo")}.should raise_error(ActiveRecord::RecordInvalid)
        end

        it "accepts core states" do
            @ir.set_described_state("successful")
        end

        it "accepts extended states" do
            # this time would normally be "overdue"
            Time.stub!(:now).and_return(Time.utc(2007, 11, 10, 00, 01)) 
            @ir.set_described_state("deadline_extended")
            @ir.display_status.should == 'Deadline extended.'
            @ir.date_deadline_extended
        end
        
        it "is not overdue if it's had the deadline extended" do
            when_overdue = Time.utc(2007, 11, 10, 00, 01) + 16.days
            Time.stub!(:now).and_return(when_overdue) 
            @ir.calculate_status.should == 'waiting_response_overdue'
        end
        
    end


    describe "when calculating the status for a school" do

        before do
            @ir = info_requests(:naughty_chicken_request)
            @ir.public_body.tag_string = "school"
            @ir.public_body.is_school?.should == true
        end

        it "has expected sent date" do
            @ir.last_event_forming_initial_request.outgoing_message.last_sent_at.strftime("%F").should == '2007-10-14'
        end

        it "has correct due date" do
            @ir.date_response_required_by.strftime("%F").should == '2007-11-09'
        end

        it "has correct very overdue after date" do
            @ir.date_very_overdue_after.strftime("%F").should == '2008-01-11' # 60 working days for schools
        end

        it "isn't overdue on due date (20 working days after request sent)" do
            Time.stub!(:now).and_return(Time.utc(2007, 11, 9, 23, 59)) 
            @ir.calculate_status.should == 'waiting_response'
        end

        it "is overdue a day after due date (20 working days after request sent)" do
            Time.stub!(:now).and_return(Time.utc(2007, 11, 10, 00, 01)) 
            @ir.calculate_status.should == 'waiting_response_overdue'
        end

        it "is still overdue 40 working days after request sent" do
            Time.stub!(:now).and_return(Time.utc(2007, 12, 10, 23, 59)) 
            @ir.calculate_status.should == 'waiting_response_overdue'
        end

        it "is still overdue the day after 40 working days after request sent" do
            Time.stub!(:now).and_return(Time.utc(2007, 12, 11, 00, 01)) 
            @ir.calculate_status.should == 'waiting_response_overdue'
        end

        it "is still overdue 60 working days after request sent" do
            Time.stub!(:now).and_return(Time.utc(2008, 01, 11, 23, 59)) 
            @ir.calculate_status.should == 'waiting_response_overdue'
        end

        it "is very overdue the day after 60 working days after request sent" do
            Time.stub!(:now).and_return(Time.utc(2008, 01, 12, 00, 01)) 
            @ir.calculate_status.should == 'waiting_response_very_overdue'
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
            Time.stub!(:now).and_return(Time.utc(2007, 11, 9, 23, 59))
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
                    true, Time.now - 21.days]})
            InfoRequest.find_old_unclassified({:conditions => ["prominence != 'backpage'"]})
        end
        
        it 'should ask the database for requests that are awaiting description, have a last response older than 21 days old, are not the holding pen and are not backpaged' do 
            InfoRequest.should_receive(:find).with(:all, 
                  {:select=>"*, (select created_at from info_request_events where info_request_events.info_request_id = info_requests.id and info_request_events.event_type = 'response' order by created_at desc limit 1) as last_response_time", 
                   :order=>"last_response_time", 
                   :conditions=>["awaiting_description = ? and (select created_at from info_request_events where info_request_events.info_request_id = info_requests.id and info_request_events.event_type = 'response' order by created_at desc limit 1) < ? and url_title != 'holding_pen'", 
                    true, Time.now - 21.days]})
            InfoRequest.find_old_unclassified
        end
        
    end
    
    describe 'when an instance is asked if it is old and unclassified' do 
        
        before do 
            Time.stub!(:now).and_return(Time.utc(2007, 11, 9, 23, 59))
            @mock_comment_event = safe_mock_model(InfoRequestEvent, :created_at => Time.now - 23.days, :event_type => 'comment')
            @mock_response_event = safe_mock_model(InfoRequestEvent, :created_at => Time.now - 22.days, :event_type => 'response')
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
        
        it 'should return false if its last response event occurred less than 21 days ago' do 
            @mock_response_event.stub!(:created_at).and_return(Time.now - 20.days)
            @info_request.is_old_unclassified?.should be_false
        end
        
        it 'should return true if it is awaiting description, isn\'t the holding pen and hasn\'t had an event in 21 days' do 
            @info_request.is_old_unclassified?.should be_true
        end
        
    end
    
end
