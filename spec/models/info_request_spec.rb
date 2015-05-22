# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: info_requests
#
#  id                        :integer          not null, primary key
#  title                     :text             not null
#  user_id                   :integer
#  public_body_id            :integer          not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  described_state           :string(255)      not null
#  awaiting_description      :boolean          default(FALSE), not null
#  prominence                :string(255)      default("normal"), not null
#  url_title                 :text             not null
#  law_used                  :string(255)      default("foi"), not null
#  allow_new_responses_from  :string(255)      default("anybody"), not null
#  handle_rejected_responses :string(255)      default("bounce"), not null
#  idhash                    :string(255)      not null
#  external_user_name        :string(255)
#  external_url              :string(255)
#  attention_requested       :boolean          default(FALSE)
#  comments_allowed          :boolean          default(TRUE), not null
#  info_request_batch_id     :integer
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InfoRequest do

    describe :new do

        it 'sets the default law used' do
            expect(InfoRequest.new.law_used).to eq('foi')
        end

        it 'sets the default law used if a body is eir-only' do
            body = FactoryGirl.create(:public_body, :tag_string => 'eir_only')
            expect(body.info_requests.build.law_used).to eq('eir')
        end

        it 'does not try to set the law used for existing requests' do
            info_request = FactoryGirl.create(:info_request)
            body = FactoryGirl.create(:public_body, :tag_string => 'eir_only')
            info_request.update_attributes(:public_body_id => body.id)
            InfoRequest.any_instance.should_not_receive(:law_used=).and_call_original
            InfoRequest.find(info_request.id)
        end
    end

    describe :move_to_public_body do

        context 'with no options' do

          it 'requires an :editor option' do
              request = FactoryGirl.create(:info_request)
              new_body = FactoryGirl.create(:public_body)
              expect {
                  request.move_to_public_body(new_body)
              }.to raise_error IndexError
          end

        end

        context 'with the :editor option' do

          it 'moves the info request to the new public body' do
              request = FactoryGirl.create(:info_request)
              new_body = FactoryGirl.create(:public_body)
              user = FactoryGirl.create(:user)
              request.move_to_public_body(new_body, :editor => user)
              request.reload
              expect(request.public_body).to eq(new_body)
          end

          it 'logs the move' do
              request = FactoryGirl.create(:info_request)
              old_body = request.public_body
              new_body = FactoryGirl.create(:public_body)
              user = FactoryGirl.create(:user)
              request.move_to_public_body(new_body, :editor => user)
              request.reload
              event = request.info_request_events.last

              expect(event.event_type).to eq('move_request')
              expect(event.params[:editor]).to eq(user)
              expect(event.params[:public_body_url_name]).to eq(new_body.url_name)
              expect(event.params[:old_public_body_url_name]).to eq(old_body.url_name)
          end

          it 'updates the law_used to the new body law' do
              request = FactoryGirl.create(:info_request)
              new_body = FactoryGirl.create(:public_body, :tag_string => 'eir_only')
              user = FactoryGirl.create(:user)
              request.move_to_public_body(new_body, :editor => user)
              request.reload
              expect(request.law_used).to eq('eir')
          end

          it 'returns the new public body' do
              request = FactoryGirl.create(:info_request)
              new_body = FactoryGirl.create(:public_body)
              user = FactoryGirl.create(:user)
              expect(request.move_to_public_body(new_body, :editor => user)).to eq(new_body)
          end

          it 'retains the existing body if the new body does not exist' do
              request = FactoryGirl.create(:info_request)
              user = FactoryGirl.create(:user)
              existing_body = request.public_body
              request.move_to_public_body(nil, :editor => user)
              request.reload
              expect(request.public_body).to eq(existing_body)
          end

          it 'returns nil if the body cannot be updated' do
              request = FactoryGirl.create(:info_request)
              user = FactoryGirl.create(:user)
              expect(request.move_to_public_body(nil, :editor => user)).to eq(nil)
          end

          it 'reindexes the info request' do
              request = FactoryGirl.create(:info_request)
              new_body = FactoryGirl.create(:public_body)
              user = FactoryGirl.create(:user)
              reindex_job = ActsAsXapian::ActsAsXapianJob.
                where(:model => 'InfoRequestEvent').
                  delete_all

              request.move_to_public_body(new_body, :editor => user)
              request.reload

              reindex_job = ActsAsXapian::ActsAsXapianJob.
                where(:model => 'InfoRequestEvent').
                  last
              expect(reindex_job.model_id).to eq(request.info_request_events.last.id)
          end

        end
    end

    describe 'when validating' do

        it 'should accept a summary with ascii characters' do
            info_request = InfoRequest.new(:title => 'abcde')
            info_request.valid?
            info_request.errors[:title].should be_empty
        end

        it 'should accept a summary with unicode characters' do
            info_request = InfoRequest.new(:title => 'кажете')
            info_request.valid?
            info_request.errors[:title].should be_empty
        end

         it 'should not accept a summary with no ascii or unicode characters' do
            info_request = InfoRequest.new(:title => '55555')
            info_request.valid?
            info_request.errors[:title].should_not be_empty
        end

        it 'should require a public body id by default' do
            info_request = InfoRequest.new
            info_request.valid?
            info_request.errors[:public_body_id].should_not be_empty
        end

        it 'should not require a public body id if it is a batch request template' do
            info_request = InfoRequest.new
            info_request.is_batch_request_template = true
            info_request.valid?
            info_request.errors[:public_body_id].should be_empty
        end
    end

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

    describe 'when managing the cache directories' do
        before do
            @info_request = info_requests(:fancy_dog_request)
        end

        it 'should return the default locale cache path without locale parts' do
            default_locale_path = File.join(Rails.root, 'cache', 'views', 'request', '101', '101')
            @info_request.foi_fragment_cache_directories.include?(default_locale_path).should == true
        end

        it 'should return the cache path for any other locales' do
            other_locale_path =  File.join(Rails.root, 'cache', 'views', 'es', 'request', '101', '101')
            @info_request.foi_fragment_cache_directories.include?(other_locale_path).should == true
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
            load_raw_emails_data
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
                                    AND (SELECT info_request_events.created_at
                                         FROM info_request_events, incoming_messages
                                         WHERE info_request_events.info_request_id = info_requests.id
                                         AND info_request_events.event_type = 'response'
                                         AND incoming_messages.id = info_request_events.incoming_message_id
                                         AND incoming_messages.prominence = 'normal'
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

        it 'should ask the database for requests that are awaiting description, have a last public response older
        than 21 days old, have a user, are not the holding pen and are not backpaged' do
            expected_conditions = ["awaiting_description = ?
                                    AND (SELECT info_request_events.created_at
                                         FROM info_request_events, incoming_messages
                                         WHERE info_request_events.info_request_id = info_requests.id
                                         AND info_request_events.event_type = 'response'
                                         AND incoming_messages.id = info_request_events.incoming_message_id
                                         AND incoming_messages.prominence = 'normal'
                                         ORDER BY created_at desc LIMIT 1) < ?
                                    AND url_title != 'holding_pen'
                                    AND user_id IS NOT NULL".split(' ').join(' '),
                                    true, Time.now - 21.days]
            expected_select = "*, (SELECT info_request_events.created_at
                                   FROM info_request_events, incoming_messages
                                   WHERE info_request_events.info_request_id = info_requests.id
                                   AND info_request_events.event_type = 'response'
                                   AND incoming_messages.id = info_request_events.incoming_message_id
                                   AND incoming_messages.prominence = 'normal'
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

    describe 'when asked for random old unclassified requests with normal prominence' do

        it "should not return requests that don't have normal prominence" do
            dog_request = info_requests(:fancy_dog_request)
            old_unclassified = InfoRequest.get_random_old_unclassified(1, :conditions => ["prominence = 'normal'"])
            old_unclassified.length.should == 1
            old_unclassified.first.should == dog_request
            dog_request.prominence = 'requester_only'
            dog_request.save!
            old_unclassified = InfoRequest.get_random_old_unclassified(1, :conditions => ["prominence = 'normal'"])
            old_unclassified.length.should == 0
            dog_request.prominence = 'hidden'
            dog_request.save!
            old_unclassified = InfoRequest.get_random_old_unclassified(1, :conditions => ["prominence = 'normal'"])
            old_unclassified.length.should == 0
        end

    end

    describe 'when asked to count old unclassified requests with normal prominence' do

        it "should not return requests that don't have normal prominence" do
            dog_request = info_requests(:fancy_dog_request)
            old_unclassified = InfoRequest.count_old_unclassified(:conditions => ["prominence = 'normal'"])
            old_unclassified.should == 1
            dog_request.prominence = 'requester_only'
            dog_request.save!
            old_unclassified = InfoRequest.count_old_unclassified(:conditions => ["prominence = 'normal'"])
            old_unclassified.should == 0
            dog_request.prominence = 'hidden'
            dog_request.save!
            old_unclassified = InfoRequest.count_old_unclassified(:conditions => ["prominence = 'normal'"])
            old_unclassified.should == 0
        end

    end

    describe 'when an instance is asked if it is old and unclassified' do

        before do
            Time.stub!(:now).and_return(Time.utc(2007, 11, 9, 23, 59))
            @info_request = FactoryGirl.create(:info_request,
                                               :prominence => 'normal',
                                               :awaiting_description => true)
            @comment_event = FactoryGirl.create(:info_request_event,
                                                :created_at => Time.now - 23.days,
                                                :event_type => 'comment',
                                                :info_request => @info_request)
            @incoming_message = FactoryGirl.create(:incoming_message,
                                                   :prominence => 'normal',
                                                   :info_request => @info_request)
            @response_event = FactoryGirl.create(:info_request_event,
                                                 :info_request => @info_request,
                                                 :created_at => Time.now - 22.days,
                                                 :event_type => 'response',
                                                 :incoming_message => @incoming_message)
            @info_request.update_attribute(:awaiting_description, true)
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
            @response_event.update_attribute(:created_at, Time.now - 20.days)
            @info_request.is_old_unclassified?.should be_false
        end

        it 'should return true if it is awaiting description, isn\'t the holding pen and hasn\'t had an event in 21 days' do
            (@info_request.is_external? || @info_request.is_old_unclassified?).should be_true
        end

    end

    describe 'when applying censor rules' do

        before do
            @global_rule = mock_model(CensorRule, :apply_to_text! => nil,
                                                  :apply_to_binary! => nil)
            @user_rule = mock_model(CensorRule, :apply_to_text! => nil,
                                                :apply_to_binary! => nil)
            @request_rule = mock_model(CensorRule, :apply_to_text! => nil,
                                                   :apply_to_binary! => nil)
            @body_rule = mock_model(CensorRule, :apply_to_text! => nil,
                                                :apply_to_binary! => nil)
            @user = mock_model(User, :censor_rules => [@user_rule])
            @body = mock_model(PublicBody, :censor_rules => [@body_rule])
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

            it 'should not raise an error if the request is a batch request template' do
                @info_request.stub!(:public_body).and_return(nil)
                @info_request.is_batch_request_template = true
                lambda{ @info_request.apply_censor_rules_to_text!(@text) }.should_not raise_error
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

    describe 'when asked for the last public response event' do

        before do
            @info_request = FactoryGirl.create(:info_request_with_incoming)
            @incoming_message = @info_request.incoming_messages.first
        end

        it 'should not return an event with a hidden prominence message' do
            @incoming_message.prominence = 'hidden'
            @incoming_message.save!
            @info_request.get_last_public_response_event.should == nil
        end

        it 'should not return an event with a requester_only prominence message' do
            @incoming_message.prominence = 'requester_only'
            @incoming_message.save!
            @info_request.get_last_public_response_event.should == nil
        end

        it 'should return an event with a normal prominence message' do
            @incoming_message.prominence = 'normal'
            @incoming_message.save!
            @info_request.get_last_public_response_event.should == @incoming_message.response_event
        end
    end

    describe 'when asked for the last public outgoing event' do

        before do
            @info_request = FactoryGirl.create(:info_request)
            @outgoing_message = @info_request.outgoing_messages.first
        end

        it 'should not return an event with a hidden prominence message' do
            @outgoing_message.prominence = 'hidden'
            @outgoing_message.save!
            @info_request.get_last_public_outgoing_event.should == nil
        end

        it 'should not return an event with a requester_only prominence message' do
            @outgoing_message.prominence = 'requester_only'
            @outgoing_message.save!
            @info_request.get_last_public_outgoing_event.should == nil
        end

        it 'should return an event with a normal prominence message' do
            @outgoing_message.prominence = 'normal'
            @outgoing_message.save!
            @info_request.get_last_public_outgoing_event.should == @outgoing_message.info_request_events.first
        end

    end

    describe 'when asked who can be sent a followup' do

        before do
            @info_request = FactoryGirl.create(:info_request_with_plain_incoming)
            @incoming_message = @info_request.incoming_messages.first
            @public_body = @info_request.public_body
        end

        it 'should not include details from a hidden prominence response' do
            @incoming_message.prominence = 'hidden'
            @incoming_message.save!
            @info_request.who_can_followup_to.should == [[@public_body.name,
                                                          @public_body.request_email,
                                                          nil]]
        end

        it 'should not include details from a requester_only prominence response' do
            @incoming_message.prominence = 'requester_only'
            @incoming_message.save!
            @info_request.who_can_followup_to.should == [[@public_body.name,
                                                          @public_body.request_email,
                                                          nil]]
        end

        it 'should include details from a normal prominence response' do
            @incoming_message.prominence = 'normal'
            @incoming_message.save!
            @info_request.who_can_followup_to.should == [[@public_body.name,
                                                          @public_body.request_email,
                                                          nil],
                                                         ['Bob Responder',
                                                          "bob@example.com",
                                                          @incoming_message.id]]
        end

    end

    describe  'when generating json for the api' do

        before do
            @user = mock_model(User, :json_for_api => { :id => 20,
                                                        :url_name => 'alaveteli_user',
                                                        :name => 'Alaveteli User',
                                                        :ban_text => '',
                                                        :about_me => 'Hi' })
        end

        it 'should return full user info for an internal request' do
            @info_request = InfoRequest.new(:user => @user)
            @info_request.user_json_for_api.should == { :id => 20,
                                                        :url_name => 'alaveteli_user',
                                                        :name => 'Alaveteli User',
                                                        :ban_text => '',
                                                        :about_me => 'Hi' }
        end
    end

    describe 'when working out a subject for request emails' do

        it 'should create a standard request subject' do
            info_request = FactoryGirl.build(:info_request)
            expected_text = "Freedom of Information request - #{info_request.title}"
            info_request.email_subject_request.should == expected_text
        end

    end

    describe 'when working out a subject for a followup emails' do

        it "should not be confused by an nil subject in the incoming message" do
            ir = info_requests(:fancy_dog_request)
            im = mock_model(IncomingMessage,
                            :subject => nil,
                            :valid_to_reply_to? => true)
            subject = ir.email_subject_followup(:incoming_message => im, :html => false)
            subject.should match(/^Re: Freedom of Information request.*fancy dog/)
        end

        it "should return a hash with the user's name for an external request" do
            @info_request = InfoRequest.new(:external_url => 'http://www.example.com',
                                            :external_user_name => 'External User')
            @info_request.user_json_for_api.should == {:name => 'External User'}
        end

        it 'should return "Anonymous user" for an anonymous external user' do
            @info_request = InfoRequest.new(:external_url => 'http://www.example.com')
            @info_request.user_json_for_api.should == {:name => 'Anonymous user'}
        end
    end
    describe "#set_described_state and #log_event" do
        context "a request" do
            let(:request) { InfoRequest.create!(:title => "my request",
                    :public_body => public_bodies(:geraldine_public_body),
                    :user => users(:bob_smith_user)) }

            context "a series of events on a request" do
                it "should have sensible events after the initial request has been made" do
                    # An initial request is sent
                    # FIXME: The logic that changes the status when a message
                    # is sent is mixed up in
                    # OutgoingMessage#record_email_delivery. So, rather than
                    # extract it (or call it) let's just duplicate what it does
                    # here for the time being.
                    request.log_event('sent', {})
                    request.set_described_state('waiting_response')

                    events = request.info_request_events
                    events.count.should == 1
                    events[0].event_type.should == "sent"
                    events[0].described_state.should == "waiting_response"
                    events[0].calculated_state.should == "waiting_response"
                end

                it "should have sensible events after a response is received to a request" do
                    # An initial request is sent
                    request.log_event('sent', {})
                    request.set_described_state('waiting_response')
                    # A response is received
                    # This is normally done in InfoRequest#receive
                    request.awaiting_description = true
                    request.log_event("response", {})

                    events = request.info_request_events
                    events.count.should == 2
                    events[0].event_type.should == "sent"
                    events[0].described_state.should == "waiting_response"
                    events[0].calculated_state.should == "waiting_response"
                    events[1].event_type.should == "response"
                    events[1].described_state.should be_nil
                    # TODO: Should calculated_status in this situation be "waiting_classification"?
                    # This would allow searches like "latest_status: waiting_classification" to be
                    # available to the user in "Advanced search"
                    events[1].calculated_state.should be_nil
                end

                it "should have sensible events after a request is classified by the requesting user" do
                    # An initial request is sent
                    request.log_event('sent', {})
                    request.set_described_state('waiting_response')
                    # A response is received
                    request.awaiting_description = true
                    request.log_event("response", {})
                    # The request is classified by the requesting user
                    # This is normally done in RequestController#describe_state
                    request.log_event("status_update", {})
                    request.set_described_state("waiting_response")

                    events = request.info_request_events
                    events.count.should == 3
                    events[0].event_type.should == "sent"
                    events[0].described_state.should == "waiting_response"
                    events[0].calculated_state.should == "waiting_response"
                    events[1].event_type.should == "response"
                    events[1].described_state.should be_nil
                    events[1].calculated_state.should == 'waiting_response'
                    events[2].event_type.should == "status_update"
                    events[2].described_state.should == "waiting_response"
                    events[2].calculated_state.should == "waiting_response"
                end

                it "should have sensible events after a normal followup is sent" do
                    # An initial request is sent
                    request.log_event('sent', {})
                    request.set_described_state('waiting_response')
                    # A response is received
                    request.awaiting_description = true
                    request.log_event("response", {})
                    # The request is classified by the requesting user
                    request.log_event("status_update", {})
                    request.set_described_state("waiting_response")
                    # A normal follow up is sent
                    # This is normally done in
                    # OutgoingMessage#record_email_delivery
                    request.log_event('followup_sent', {})
                    request.set_described_state('waiting_response')

                    events = request.info_request_events
                    events.count.should == 4
                    events[0].event_type.should == "sent"
                    events[0].described_state.should == "waiting_response"
                    events[0].calculated_state.should == "waiting_response"
                    events[1].event_type.should == "response"
                    events[1].described_state.should be_nil
                    events[1].calculated_state.should == 'waiting_response'
                    events[2].event_type.should == "status_update"
                    events[2].described_state.should == "waiting_response"
                    events[2].calculated_state.should == "waiting_response"
                    events[3].event_type.should == "followup_sent"
                    events[3].described_state.should == "waiting_response"
                    events[3].calculated_state.should == "waiting_response"
                end

                it "should have sensible events after a user classifies the request after a follow up" do
                    # An initial request is sent
                    request.log_event('sent', {})
                    request.set_described_state('waiting_response')
                    # A response is received
                    request.awaiting_description = true
                    request.log_event("response", {})
                    # The request is classified by the requesting user
                    request.log_event("status_update", {})
                    request.set_described_state("waiting_response")
                    # A normal follow up is sent
                    request.log_event('followup_sent', {})
                    request.set_described_state('waiting_response')
                    # The request is classified by the requesting user
                    request.log_event("status_update", {})
                    request.set_described_state("waiting_response")

                    events = request.info_request_events
                    events.count.should == 5
                    events[0].event_type.should == "sent"
                    events[0].described_state.should == "waiting_response"
                    events[0].calculated_state.should == "waiting_response"
                    events[1].event_type.should == "response"
                    events[1].described_state.should be_nil
                    events[1].calculated_state.should == 'waiting_response'
                    events[2].event_type.should == "status_update"
                    events[2].described_state.should == "waiting_response"
                    events[2].calculated_state.should == "waiting_response"
                    events[3].event_type.should == "followup_sent"
                    events[3].described_state.should == "waiting_response"
                    events[3].calculated_state.should == "waiting_response"
                    events[4].event_type.should == "status_update"
                    events[4].described_state.should == "waiting_response"
                    events[4].calculated_state.should == "waiting_response"
                end
            end

            context "another series of events on a request" do
                it "should have sensible event states" do
                    # An initial request is sent
                    request.log_event('sent', {})
                    request.set_described_state('waiting_response')
                    # An internal review is requested
                    request.log_event('followup_sent', {})
                    request.set_described_state('internal_review')

                    events = request.info_request_events
                    events.count.should == 2
                    events[0].event_type.should == "sent"
                    events[0].described_state.should == "waiting_response"
                    events[0].calculated_state.should == "waiting_response"
                    events[1].event_type.should == "followup_sent"
                    events[1].described_state.should == "internal_review"
                    events[1].calculated_state.should == "internal_review"
                end

                it "should have sensible event states" do
                    # An initial request is sent
                    request.log_event('sent', {})
                    request.set_described_state('waiting_response')
                    # An internal review is requested
                    request.log_event('followup_sent', {})
                    request.set_described_state('internal_review')
                    # The user marks the request as rejected
                    request.log_event("status_update", {})
                    request.set_described_state("rejected")

                    events = request.info_request_events
                    events.count.should == 3
                    events[0].event_type.should == "sent"
                    events[0].described_state.should == "waiting_response"
                    events[0].calculated_state.should == "waiting_response"
                    events[1].event_type.should == "followup_sent"
                    events[1].described_state.should == "internal_review"
                    events[1].calculated_state.should == "internal_review"
                    events[2].event_type.should == "status_update"
                    events[2].described_state.should == "rejected"
                    events[2].calculated_state.should == "rejected"
                end
            end

            context "another series of events on a request" do
                it "should have sensible event states" do
                    # An initial request is sent
                    request.log_event('sent', {})
                    request.set_described_state('waiting_response')
                    # The user marks the request as successful (I know silly but someone did
                    # this in https://www.whatdotheyknow.com/request/family_support_worker_redundanci)
                    request.log_event("status_update", {})
                    request.set_described_state("successful")

                    events = request.info_request_events
                    events.count.should == 2
                    events[0].event_type.should == "sent"
                    events[0].described_state.should == "waiting_response"
                    events[0].calculated_state.should == "waiting_response"
                    events[1].event_type.should == "status_update"
                    events[1].described_state.should == "successful"
                    events[1].calculated_state.should == "successful"
                end

                it "should have sensible event states" do
                    # An initial request is sent
                    request.log_event('sent', {})
                    request.set_described_state('waiting_response')

                    # A response is received
                    request.awaiting_description = true
                    request.log_event("response", {})

                    # The user marks the request as successful
                    request.log_event("status_update", {})
                    request.set_described_state("successful")

                    events = request.info_request_events
                    events.count.should == 3
                    events[0].event_type.should == "sent"
                    events[0].described_state.should == "waiting_response"
                    events[0].calculated_state.should == "waiting_response"
                    events[1].event_type.should == "response"
                    events[1].described_state.should be_nil
                    events[1].calculated_state.should == "successful"
                    events[2].event_type.should == "status_update"
                    events[2].described_state.should == "successful"
                    events[2].calculated_state.should == "successful"
                end
            end

            context "another series of events on a request" do
                it "should have sensible event states" do
                    # An initial request is sent
                    request.log_event('sent', {})
                    request.set_described_state('waiting_response')
                    # An admin sets the status of the request to 'gone postal' using
                    # the admin interface
                    request.log_event("edit", {})
                    request.set_described_state("gone_postal")

                    events = request.info_request_events
                    events.count.should == 2
                    events[0].event_type.should == "sent"
                    events[0].described_state.should == "waiting_response"
                    events[0].calculated_state.should == "waiting_response"
                    events[1].event_type.should == "edit"
                    events[1].described_state.should == "gone_postal"
                    events[1].calculated_state.should == "gone_postal"
                end
            end
        end
    end

    describe 'when saving an info_request' do

        before do
            @info_request = InfoRequest.new(:external_url => 'http://www.example.com',
                                            :external_user_name => 'Example User',
                                            :title => 'Some request or other',
                                            :public_body => public_bodies(:geraldine_public_body))
        end

        it "should call purge_in_cache and update_counter_cache" do
            @info_request.should_receive(:purge_in_cache)
            # Twice - once for save, once for destroy:
            @info_request.should_receive(:update_counter_cache).twice
            @info_request.save!
            @info_request.destroy
        end

    end

    describe 'when destroying an info_request' do

        before do
            @info_request = InfoRequest.new(:external_url => 'http://www.example.com',
                                            :external_user_name => 'Example User',
                                            :title => 'Some request or other',
                                            :public_body => public_bodies(:geraldine_public_body))
        end

        it "should call update_counter_cache" do
            @info_request.save!
            @info_request.should_receive(:update_counter_cache)
            @info_request.destroy
        end

    end

    describe 'when changing a described_state' do

        it "should change the counts on its PublicBody without saving a new version" do
            pb = public_bodies(:geraldine_public_body)
            old_version_count = pb.versions.count
            old_successful_count = pb.info_requests_successful_count
            old_not_held_count = pb.info_requests_not_held_count
            ir = InfoRequest.new(:external_url => 'http://www.example.com',
                                 :external_user_name => 'Example User',
                                 :title => 'Some request or other',
                                 :described_state => 'partially_successful',
                                 :public_body => pb)
            ir.save!
            pb.info_requests_successful_count.should == (old_successful_count + 1)
            ir.described_state = 'not_held'
            ir.save!
            pb.reload
            pb.info_requests_successful_count.should == old_successful_count
            pb.info_requests_not_held_count.should == (old_not_held_count + 1)
            ir.described_state = 'successful'
            ir.save!
            pb.reload
            pb.info_requests_successful_count.should == (old_successful_count + 1)
            pb.info_requests_not_held_count.should == old_not_held_count
            ir.destroy
            pb.reload
            pb.info_requests_successful_count.should == old_successful_count
            pb.info_requests_successful_count.should == old_not_held_count
            pb.versions.count.should == old_version_count
        end

    end

    describe InfoRequest, 'when getting similar requests' do

        before(:each) do
            get_fixtures_xapian_index
        end

        it 'should return similar requests' do
            similar, more = info_requests(:spam_1_request).similar_requests(1)
            similar.results.first[:model].info_request.should == info_requests(:spam_2_request)
        end

        it 'should return a flag set to true' do
            similar, more = info_requests(:spam_1_request).similar_requests(1)
            more.should be_true
        end

    end

    describe InfoRequest, 'when constructing the list of recent requests' do

        before(:each) do
            get_fixtures_xapian_index
        end

        describe 'when there are fewer than five successful requests' do

            it 'should list the most recently sent and successful requests by the creation date of the
                request event' do
                # Make sure the newest response is listed first even if a request
                # with an older response has a newer comment or was reclassified more recently:
                # https://github.com/mysociety/alaveteli/issues/370
                #
                # This is a deliberate behaviour change, in that the
                # previous behaviour (showing more-recently-reclassified
                # requests first) was intentional.
                request_events, request_events_all_successful = InfoRequest.recent_requests
                previous = nil
                request_events.each do |event|
                    if previous
                        previous.created_at.should be >= event.created_at
                    end
                    ['sent', 'response'].include?(event.event_type).should be_true
                    if event.event_type == 'response'
                        ['successful', 'partially_successful'].include?(event.calculated_state).should be_true
                    end
                    previous = event
                end
            end
        end

        it 'should coalesce duplicate requests' do
            request_events, request_events_all_successful = InfoRequest.recent_requests
            request_events.map(&:info_request).select{|x|x.url_title =~ /^spam/}.length.should == 1
        end
    end

    describe InfoRequest, "when constructing a list of requests by query" do

        before(:each) do
            load_raw_emails_data
            get_fixtures_xapian_index
        end

        def apply_filters(filters)
            results = InfoRequest.request_list(filters, page=1, per_page=100, max_results=100)
            results[:results].map(&:info_request)
        end

        it "should filter requests" do
            apply_filters(:latest_status => 'all').should =~ InfoRequest.all

            # default sort order is the request with the most recently created event first
            apply_filters(:latest_status => 'all').should == InfoRequest.all(
                :order => "(SELECT max(info_request_events.created_at)
                            FROM info_request_events
                            WHERE info_request_events.info_request_id = info_requests.id)
                            DESC")

            apply_filters(:latest_status => 'successful').should =~ InfoRequest.all(
                :conditions => "id in (
                    SELECT info_request_id
                    FROM info_request_events
                    WHERE NOT EXISTS (
                        SELECT *
                        FROM info_request_events later_events
                        WHERE later_events.created_at > info_request_events.created_at
                        AND later_events.info_request_id = info_request_events.info_request_id
                        AND later_events.described_state IS NOT null
                    )
                    AND info_request_events.described_state IN ('successful', 'partially_successful')
                )")

        end

        it "should filter requests by date" do
            # The semantics of the search are that it finds any InfoRequest
            # that has any InfoRequestEvent created in the specified range
            filters = {:latest_status => 'all', :request_date_before => '13/10/2007'}
            apply_filters(filters).should =~ InfoRequest.all(
                :conditions => "id IN (SELECT info_request_id
                                       FROM info_request_events
                                       WHERE created_at < '2007-10-13'::date)")

            filters = {:latest_status => 'all', :request_date_after => '13/10/2007'}
            apply_filters(filters).should =~ InfoRequest.all(
                :conditions => "id IN (SELECT info_request_id
                                       FROM info_request_events
                                       WHERE created_at > '2007-10-13'::date)")

            filters = {:latest_status => 'all',
                       :request_date_after => '13/10/2007',
                       :request_date_before => '01/11/2007'}
            apply_filters(filters).should =~ InfoRequest.all(
                :conditions => "id IN (SELECT info_request_id
                                       FROM info_request_events
                                       WHERE created_at BETWEEN '2007-10-13'::date
                                       AND '2007-11-01'::date)")
        end


        it "should list internal_review requests as unresolved ones" do

            # This doesn’t precisely duplicate the logic of the actual
            # query, but it is close enough to give the same result with
            # the current set of test data.
            results = apply_filters(:latest_status => 'awaiting')
            results.should =~ InfoRequest.all(
                :conditions => "id IN (SELECT info_request_id
                                       FROM info_request_events
                                       WHERE described_state in (
                        'waiting_response', 'waiting_clarification',
                        'internal_review', 'gone_postal', 'error_message', 'requires_admin'
                    ) and not exists (
                        select *
                        from info_request_events later_events
                        where later_events.created_at > info_request_events.created_at
                        and later_events.info_request_id = info_request_events.info_request_id
                    ))")


            results.include?(info_requests(:fancy_dog_request)).should == false

            event = info_request_events(:useless_incoming_message_event)
            event.described_state = event.calculated_state = "internal_review"
            event.save!
            rebuild_xapian_index
            results = apply_filters(:latest_status => 'awaiting')
            results.include?(info_requests(:fancy_dog_request)).should == true
        end


    end

    describe 'when destroying a message' do

        it 'can destroy a request with comments and censor rules' do
            info_request = FactoryGirl.create(:info_request)
            censor_rule = FactoryGirl.create(:censor_rule, :info_request => info_request)
            comment = FactoryGirl.create(:comment, :info_request => info_request)
            info_request.reload
            info_request.fully_destroy

            InfoRequest.where(:id => info_request.id).should be_empty
            CensorRule.where(:id => censor_rule.id).should be_empty
            Comment.where(:id => comment.id).should be_empty
        end

    end
end
