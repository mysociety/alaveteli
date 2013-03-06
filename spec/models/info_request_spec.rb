require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InfoRequest do

    describe 'when generating a user name slug' do

        before do
            @public_body = mock_model(PublicBody, :url_name => 'example_body',
                                                  :eir_only? => false)
            @info_request = InfoRequest.new(:external_url => 'http://www.example.com',
                                            :external_user_name => 'Example User',
                                            :public_body => @public_body)
        end

        it 'should generate a slug for an example user name' do
            @info_request.user_name_slug.should == 'example_body_example_user'
        end

    end

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

        it 'should ask for requests using any offset param supplied' do
            InfoRequest.should_receive(:find).with(:all, {:select => anything,
                                                          :order => anything,
                                                          :conditions=> anything,
                                                          :offset => 100})
            InfoRequest.find_old_unclassified(:offset => 100)
        end

        it 'should not limit the number of requests returned by default' do
            InfoRequest.should_not_receive(:find).with(:all, {:select => anything,
                                                              :order => anything,
                                                              :conditions=> anything,
                                                              :limit => anything})
            InfoRequest.find_old_unclassified
        end

        it 'should add extra conditions if supplied' do
            expected_conditions = ["awaiting_description = ?
                                    AND (SELECT created_at
                                         FROM info_request_events
                                         WHERE info_request_events.info_request_id = info_requests.id
                                         AND info_request_events.event_type = 'response'
                                         ORDER BY created_at desc LIMIT 1) < ?
                                    AND url_title != 'holding_pen'
                                    AND user_id IS NOT NULL
                                    AND prominence != 'backpage'".split(' ').join(' '),
                                    true, Time.now - 21.days]
            # compare conditions ignoring whitespace differences
            InfoRequest.should_receive(:find) do |all, query_params|
                query_string = query_params[:conditions][0]
                query_params[:conditions][0] = query_string.split(' ').join(' ')
                query_params[:conditions].should == expected_conditions
            end
            InfoRequest.find_old_unclassified({:conditions => ["prominence != 'backpage'"]})
        end

        it 'should ask the database for requests that are awaiting description, have a last response older
        than 21 days old, have a user, are not the holding pen and are not backpaged' do
            expected_conditions = ["awaiting_description = ?
                                    AND (SELECT created_at
                                         FROM info_request_events
                                         WHERE info_request_events.info_request_id = info_requests.id
                                         AND info_request_events.event_type = 'response'
                                         ORDER BY created_at desc LIMIT 1) < ?
                                    AND url_title != 'holding_pen'
                                    AND user_id IS NOT NULL".split(' ').join(' '),
                                    true, Time.now - 21.days]
            expected_select = "*, (SELECT created_at
                                   FROM info_request_events
                                   WHERE info_request_events.info_request_id = info_requests.id
                                   AND info_request_events.event_type = 'response'
                                   ORDER BY created_at desc LIMIT 1)
                                   AS last_response_time".split(' ').join(' ')
            InfoRequest.should_receive(:find) do |all, query_params|
                query_string = query_params[:conditions][0]
                query_params[:conditions][0] = query_string.split(' ').join(' ')
                query_params[:conditions].should == expected_conditions
                query_params[:select].split(' ').join(' ').should == expected_select
                query_params[:order].should == "last_response_time"
            end
            InfoRequest.find_old_unclassified
        end

    end

    describe 'when an instance is asked if it is old and unclassified' do

        before do
            Time.stub!(:now).and_return(Time.utc(2007, 11, 9, 23, 59))
            @mock_comment_event = safe_mock_model(InfoRequestEvent, :created_at => Time.now - 23.days, :event_type => 'comment', :response? => false)
            @mock_response_event = safe_mock_model(InfoRequestEvent, :created_at => Time.now - 22.days, :event_type => 'response', :response? => true)
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
            (@info_request.is_external? || @info_request.is_old_unclassified?).should be_true
        end

    end

    describe 'when applying censor rules' do

        before do
            @global_rule = safe_mock_model(CensorRule, :apply_to_text! => nil,
                                                  :apply_to_binary! => nil)
            @user_rule = safe_mock_model(CensorRule, :apply_to_text! => nil,
                                                :apply_to_binary! => nil)
            @request_rule = safe_mock_model(CensorRule, :apply_to_text! => nil,
                                                   :apply_to_binary! => nil)
            @body_rule = safe_mock_model(CensorRule, :apply_to_text! => nil,
                                                :apply_to_binary! => nil)
            @user = safe_mock_model(User, :censor_rules => [@user_rule])
            @body = safe_mock_model(PublicBody, :censor_rules => [@body_rule])
            @info_request = InfoRequest.new(:prominence => 'normal',
                                            :awaiting_description => true,
                                            :title => 'title')
            @info_request.stub!(:user).and_return(@user)
            @info_request.stub!(:censor_rules).and_return([@request_rule])
            @info_request.stub!(:public_body).and_return(@body)
            @text = 'some text'
            CensorRule.stub!(:global).and_return(mock('global context', :all => [@global_rule]))
        end

        context "when applying censor rules to text" do

            it "should apply a global censor rule" do
                @global_rule.should_receive(:apply_to_text!).with(@text)
                @info_request.apply_censor_rules_to_text!(@text)
            end

            it 'should apply a user rule' do
                @user_rule.should_receive(:apply_to_text!).with(@text)
                @info_request.apply_censor_rules_to_text!(@text)
            end

            it 'should not raise an error if there is no user' do
                @info_request.user_id = nil
                lambda{ @info_request.apply_censor_rules_to_text!(@text) }.should_not raise_error
            end

            it 'should apply a rule from the body associated with the request' do
                @body_rule.should_receive(:apply_to_text!).with(@text)
                @info_request.apply_censor_rules_to_text!(@text)
            end

            it 'should apply a request rule' do
                @request_rule.should_receive(:apply_to_text!).with(@text)
                @info_request.apply_censor_rules_to_text!(@text)
            end

        end

        context 'when applying censor rules to binary files' do

            it "should apply a global censor rule" do
                @global_rule.should_receive(:apply_to_binary!).with(@text)
                @info_request.apply_censor_rules_to_binary!(@text)
            end

            it 'should apply a user rule' do
                @user_rule.should_receive(:apply_to_binary!).with(@text)
                @info_request.apply_censor_rules_to_binary!(@text)
            end

            it 'should not raise an error if there is no user' do
                @info_request.user_id = nil
                lambda{ @info_request.apply_censor_rules_to_binary!(@text) }.should_not raise_error
            end

            it 'should apply a rule from the body associated with the request' do
                @body_rule.should_receive(:apply_to_binary!).with(@text)
                @info_request.apply_censor_rules_to_binary!(@text)
            end

            it 'should apply a request rule' do
                @request_rule.should_receive(:apply_to_binary!).with(@text)
                @info_request.apply_censor_rules_to_binary!(@text)
            end

        end

    end

    describe 'when an instance is asked if all can view it' do

        before do
            @info_request = InfoRequest.new
        end

        it 'should return true if its prominence is normal' do
            @info_request.prominence = 'normal'
            @info_request.all_can_view?.should == true
        end

        it 'should return true if its prominence is backpage' do
            @info_request.prominence = 'backpage'
            @info_request.all_can_view?.should == true
        end

        it 'should return false if its prominence is hidden' do
            @info_request.prominence = 'hidden'
            @info_request.all_can_view?.should == false
        end

        it 'should return false if its prominence is requester_only' do
            @info_request.prominence = 'requester_only'
            @info_request.all_can_view?.should == false
        end

    end

end
