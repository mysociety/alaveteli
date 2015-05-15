# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApiController, "when using the API" do

    describe 'checking API keys' do
        before do
            @number_of_requests = InfoRequest.count
            @request_data = {
                'title' => 'Tell me about your chickens',
                'body' => "Dear Sir,\n\nI should like to know about your chickens.\n\nYours in faith,\nBob\n",
                'external_url' => 'http://www.example.gov.uk/foi/chickens_23',
                'external_user_name' => 'Bob Smith'
            }
        end

        it 'should check that an API key is given as a param' do
            expect {
                post :create_request, :request_json => @request_data.to_json
            }.to raise_error ApplicationController::PermissionDenied
            InfoRequest.count.should == @number_of_requests
        end

        it 'should check the API key' do
            expect {
                post :create_request,
                     :k => 'This is not really an API key',
                     :request_json => @request_data.to_json
            }.to raise_error ApplicationController::PermissionDenied
            InfoRequest.count.should == @number_of_requests
        end
    end

    def _create_request
        post :create_request,
             :k => public_bodies(:geraldine_public_body).api_key,
             :request_json => {
                 'title' => 'Tell me about your chickens',
                 'body' => "Dear Sir,\n\nI should like to know about your chickens.\n\nYours in faith,\nBob\n",
                 'external_url' => 'http://www.example.gov.uk/foi/chickens_23',
                 'external_user_name' => 'Bob Smith'
             }.to_json
        response.content_type.should == 'application/json'
        ActiveSupport::JSON.decode(response.body)['id']
    end

    # POST /api/v2/request.json
    describe 'creating a request' do
        it 'should create a new request from a POST' do
            number_of_requests = InfoRequest.count(
            :conditions => [
                "public_body_id = ?",
                public_bodies(:geraldine_public_body).id
            ]
            )

            request_data = {
                'title' => 'Tell me about your chickens',
                'body' => "Dear Sir,\n\nI should like to know about your chickens.\n\nYours in faith,\nBob\n",
                'external_url' => 'http://www.example.gov.uk/foi/chickens_23',
                'external_user_name' => 'Bob Smith',
            }

            post :create_request,
                 :k => public_bodies(:geraldine_public_body).api_key,
                 :request_json => request_data.to_json
            response.should be_success

            response.content_type.should == 'application/json'
            response_body = ActiveSupport::JSON.decode(response.body)
            response_body['errors'].should be_nil
            response_body['url'].should =~ /^http/

            InfoRequest.count(:conditions => [
                'public_body_id = ?',
                public_bodies(:geraldine_public_body).id]
            ).should == number_of_requests + 1

            new_request = InfoRequest.find(response_body['id'])
            new_request.user_id.should be_nil
            new_request.external_user_name.should == request_data['external_user_name']
            new_request.external_url.should == request_data['external_url']

            new_request.title.should == request_data['title']
            new_request.last_event_forming_initial_request.outgoing_message.body.should == request_data['body'].strip

            new_request.public_body_id.should == public_bodies(:geraldine_public_body).id
            new_request.info_request_events.size.should == 1
            new_request.info_request_events[0].event_type.should == 'sent'
            new_request.info_request_events[0].calculated_state.should == 'waiting_response'
        end
    end

    # POST /api/v2/request/:id/add_correspondence.json
    describe 'adding correspondence to a request' do
        it 'should add a response to a request' do
            # First we need an external request
            request_id = info_requests(:external_request).id

            # Initially it has no incoming messages
            IncomingMessage.count(:conditions => ["info_request_id = ?", request_id]).should == 0

            # Now add one
            sent_at = '2012-05-28T12:35:39+01:00'
            response_body = "Thank you for your request for information, which we are handling in accordance with the Freedom of Information Act 2000. You will receive a response within 20 working days or before the next full moon, whichever is sooner.\n\nYours sincerely,\nJohn Gandermulch,\nExample Council FOI Officer\n"
            post :add_correspondence,
                 :k => public_bodies(:geraldine_public_body).api_key,
                 :id => request_id,
                 :correspondence_json => {
                     'direction' => 'response',
                     'sent_at' => sent_at,
                     'body' => response_body
                 }.to_json

            # And make sure it worked
            response.should be_success
            incoming_messages = IncomingMessage.all(:conditions => ['info_request_id = ?', request_id])
            incoming_messages.count.should == 1
            incoming_message = incoming_messages[0]

            incoming_message.sent_at.should == Time.iso8601(sent_at)
            incoming_message.get_main_body_text_folded.should be_equal_modulo_whitespace_to(response_body)
        end

        it 'should add a followup to a request' do
            # First we need an external request
            request_id = info_requests(:external_request).id

            # Initially it has one outgoing message
            OutgoingMessage.count(:conditions => ['info_request_id = ?', request_id]).should == 1

            # Add another, as a followup
            sent_at = '2012-05-29T12:35:39+01:00'
            followup_body = "Pls answer ASAP.\nkthxbye\n"
            post :add_correspondence,
                 :k => public_bodies(:geraldine_public_body).api_key,
                 :id => request_id,
                 :correspondence_json => {
                     'direction' => 'request',
                     'sent_at' => sent_at,
                     'body' => followup_body
                 }.to_json

            # Make sure it worked
            response.should be_success
            followup_messages = OutgoingMessage.all(
                :conditions => ["info_request_id = ? and message_type = 'followup'", request_id]
            )
            followup_messages.size.should == 1
            followup_message = followup_messages[0]

            followup_message.last_sent_at.should == Time.iso8601(sent_at)
            followup_message.body.should == followup_body.strip
        end

        it 'should update the status if a valid state is supplied' do
            # First we need an external request
            request_id = info_requests(:external_request).id

            # Initially it has no incoming messages
            IncomingMessage.count(:conditions => ['info_request_id = ?', request_id]).should == 0

            # Now add one
            sent_at = '2012-05-28T12:35:39+01:00'
            response_body = "Thank you for your request for information, which we are handling in accordance with the Freedom of Information Act 2000. You will receive a response within 20 working days or before the next full moon, whichever is sooner.\n\nYours sincerely,\nJohn Gandermulch,\nExample Council FOI Officer\n"
            post :add_correspondence,
                 :k => public_bodies(:geraldine_public_body).api_key,
                 :id => request_id,
                 :state => 'successful',
                 :correspondence_json => {
                     'direction' => 'response',
                     'sent_at' => sent_at,
                     'body' => response_body,
                 }.to_json

            # And make sure it worked
            response.should be_success
            incoming_messages = IncomingMessage.all(:conditions => ['info_request_id = ?', request_id])
            incoming_messages.count.should == 1
            request = InfoRequest.find_by_id(request_id)
            request.described_state.should == 'successful'
        end

        it 'should raise a JSON 500 error if an invalid state is supplied' do
            # First we need an external request
            request_id = info_requests(:external_request).id

            # Initially it has no incoming messages
            IncomingMessage.count(:conditions => ['info_request_id = ?', request_id]).should == 0

            # Now add one
            sent_at = '2012-05-28T12:35:39+01:00'
            response_body = "Thank you for your request for information, which we are handling in accordance with the Freedom of Information Act 2000. You will receive a response within 20 working days or before the next full moon, whichever is sooner.\n\nYours sincerely,\nJohn Gandermulch,\nExample Council FOI Officer\n"
            post :add_correspondence,
                 :k => public_bodies(:geraldine_public_body).api_key,
                 :id => request_id,
                 :state => 'random_string',
                 :correspondence_json => {
                     'direction' => 'response',
                     'sent_at' => sent_at,
                     'body' => response_body,
                 }.to_json

            # And make sure it worked
            response.status.should == 500
            ActiveSupport::JSON.decode(response.body)['errors'].should == [
                "'random_string' is not a valid request state"]

            incoming_messages = IncomingMessage.all(:conditions => ['info_request_id = ?', request_id])
            incoming_messages.count.should == 0
            request = InfoRequest.find_by_id(request_id)
            request.described_state.should == 'waiting_response'
        end

        it 'should not allow internal requests to be updated' do
            n_incoming_messages = IncomingMessage.count
            n_outgoing_messages = OutgoingMessage.count

            request_id = info_requests(:naughty_chicken_request).id
            post :add_correspondence,
                 :k => public_bodies(:geraldine_public_body).api_key,
                 :id => request_id,
                 :correspondence_json => {
                     'direction' => 'request',
                     'sent_at' => Time.now.iso8601,
                     'body' => 'xxx'
                 }.to_json

            response.status.should == 403
            ActiveSupport::JSON.decode(response.body)['errors'].should == [
                "Request #{request_id} cannot be updated using the API"]

            IncomingMessage.count.should == n_incoming_messages
            OutgoingMessage.count.should == n_outgoing_messages
        end

        it 'should not allow other people\'s requests to be updated' do
            request_id = _create_request
            n_incoming_messages = IncomingMessage.count
            n_outgoing_messages = OutgoingMessage.count

            post :add_correspondence,
                 :k => public_bodies(:humpadink_public_body).api_key,
                 :id => request_id,
                 :correspondence_json => {
                     'direction' => 'request',
                     'sent_at' => Time.now.iso8601,
                     'body' => 'xxx'
                 }.to_json

            response.status.should == 403
            ActiveSupport::JSON.decode(response.body)['errors'].should == [
                "You do not own request #{request_id}"]

            IncomingMessage.count.should == n_incoming_messages
            OutgoingMessage.count.should == n_outgoing_messages
        end

        it 'should return a JSON 404 error for non-existent requests' do
            request_id = '123459876'
            InfoRequest.stub(:find_by_id).with(request_id).and_return(nil)
            sent_at = '2012-05-28T12:35:39+01:00'
            response_body = "Thank you for your request for information, which we are handling in accordance with the Freedom of Information Act 2000. You will receive a response within 20 working days or before the next full moon, whichever is sooner.\n\nYours sincerely,\nJohn Gandermulch,\nExample Council FOI Officer\n"
            post :add_correspondence,
                 :k => public_bodies(:geraldine_public_body).api_key,
                 :id => request_id,
                 :correspondence_json => {
                     'direction' => 'response',
                     'sent_at' => sent_at,
                     'body' => response_body
                 }.to_json
            response.status.should == 404
            ActiveSupport::JSON.decode(response.body)['errors'].should == ['Could not find request 123459876']
        end

        it 'should return a JSON 403 error if we try to add correspondence to a request we don\'t own' do
            request_id = info_requests(:naughty_chicken_request).id
            sent_at = '2012-05-28T12:35:39+01:00'
            response_body = "Thank you for your request for information, which we are handling in accordance with the Freedom of Information Act 2000. You will receive a response within 20 working days or before the next full moon, whichever is sooner.\n\nYours sincerely,\nJohn Gandermulch,\nExample Council FOI Officer\n"
            post :add_correspondence,
                 :k => public_bodies(:geraldine_public_body).api_key,
                 :id => request_id,
                 :correspondence_json => {
                     'direction' => 'response',
                     'sent_at' => sent_at,
                     'body' => response_body
                 }.to_json
            response.status.should == 403
            ActiveSupport::JSON.decode(response.body)['errors'].should == ["Request #{request_id} cannot be updated using the API"]
        end

        it 'should not allow files to be attached to a followup' do
            post :add_correspondence,
                 :k => public_bodies(:geraldine_public_body).api_key,
                 :id => info_requests(:external_request).id,
                 :correspondence_json => {
                     'direction' => 'request',
                     'sent_at' => Time.now.iso8601,
                     'body' => 'Are you joking, or are you serious?'
                 }.to_json,
                 :attachments => [
                     fixture_file_upload('/files/tfl.pdf')
                 ]

            # Make sure it worked
            response.status.should == 500
            errors = ActiveSupport::JSON.decode(response.body)['errors']
            errors.should == ["You cannot attach files to messages in the 'request' direction"]
        end

        it 'should allow files to be attached to a response' do
            # First we need an external request
            request_id = info_requests(:external_request).id

            # Initially it has no incoming messages
            IncomingMessage.count(:conditions => ['info_request_id = ?', request_id]).should == 0

            # Now add one
            sent_at = '2012-05-28T12:35:39+01:00'
            response_body = "Thank you for your request for information, which we are handling in accordance with the Freedom of Information Act 2000. You will receive a response within 20 working days or before the next full moon, whichever is sooner.\n\nYours sincerely,\nJohn Gandermulch,\nExample Council FOI Officer\n"
            post :add_correspondence,
                 :k => public_bodies(:geraldine_public_body).api_key,
                 :id => request_id,
                 :correspondence_json => {
                     'direction' => 'response',
                     'sent_at' => sent_at,
                     'body' => response_body
                 }.to_json,
                 :attachments => [
                     fixture_file_upload('/files/tfl.pdf')
                 ]

            # And make sure it worked
            response.should be_success
            incoming_messages = IncomingMessage.all(:conditions => ['info_request_id = ?', request_id])
            incoming_messages.count.should == 1
            incoming_message = incoming_messages[0]

            incoming_message.sent_at.should == Time.iso8601(sent_at)
            incoming_message.get_main_body_text_folded.should be_equal_modulo_whitespace_to(response_body)

            # Get the attachment
            attachments = incoming_message.get_attachments_for_display
            attachments.size.should == 1
            attachment = attachments[0]
            attachment.filename.should == 'tfl.pdf'
            attachment.body.should == load_file_fixture('tfl.pdf')
        end
    end

    # POST /api/v2/request/:id/update.json
    describe 'updating a request\'s status' do
        it 'should update the status' do
            # First we need an external request
            request_id = info_requests(:external_request).id
            request = InfoRequest.find_by_id(request_id)

            # Its status should be the default for a new request
            request.described_state.should == 'waiting_response'

            # Now accept an update
            post :update_state,
                 :k => public_bodies(:geraldine_public_body).api_key,
                 :id => request_id,
                 :state => 'partially_successful'

            # It should have updated the status
            request = InfoRequest.find_by_id(request_id)
            request.described_state.should == 'partially_successful'

            # It should have recorded the status_update event
            last_event = request.info_request_events.last
            last_event.event_type.should == 'status_update'
            last_event.described_state.should == 'partially_successful'
            last_event.params_yaml.should =~ /script: Geraldine Quango on behalf of requester via API/
        end

        it 'should return a JSON 500 error if an invalid state is sent' do
            # First we need an external request
            request_id = info_requests(:external_request).id
            request = InfoRequest.find_by_id(request_id)

            # Its status should be the default for a new request
            request.described_state.should == 'waiting_response'

            # Now post an invalid update
            post :update_state,
                 :k => public_bodies(:geraldine_public_body).api_key,
                 :id => request_id,
                 :state => 'random_string'

            # Check that the error has been raised...
            response.status.should == 500
            ActiveSupport::JSON.decode(response.body)['errors'].should == ["'random_string' is not a valid request state"]

            # ..and that the status hasn't been updated
            request = InfoRequest.find_by_id(request_id)
            request.described_state.should == 'waiting_response'
        end

        it 'should return a JSON 404 error for non-existent requests' do
            request_id = '123459876'
            InfoRequest.stub(:find_by_id).with(request_id).and_return(nil)

            post :update_state,
                 :k => public_bodies(:geraldine_public_body).api_key,
                 :id => request_id,
                 :state => "successful"

            response.status.should == 404
            ActiveSupport::JSON.decode(response.body)['errors'].should == ['Could not find request 123459876']
        end

        it 'should return a JSON 403 error if we try to add correspondence to a request we don\'t own' do
            request_id = info_requests(:naughty_chicken_request).id

            post :update_state,
                 :k => public_bodies(:geraldine_public_body).api_key,
                 :id => request_id,
                 :state => 'successful'

            response.status.should == 403
            ActiveSupport::JSON.decode(response.body)['errors'].should == ["Request #{request_id} cannot be updated using the API"]
        end
    end

    # GET /api/v2/request/:id.json
    describe 'showing request info' do
        it 'should show information about a request' do
            info_request = info_requests(:naughty_chicken_request)

            get :show_request,
                :k => public_bodies(:geraldine_public_body).api_key,
                :id => info_request.id

            response.should be_success
            assigns[:request].id.should == info_request.id

            r = ActiveSupport::JSON.decode(response.body)
            r['title'].should == info_request.title
            # Let’s not test all the fields here, because it would
            # essentially just be a matter of copying the code that
            # assigns them and changing assignment to an equality
            # check, which does not really test anything at all.
        end

        it 'should show information about an external request' do
            info_request = info_requests(:external_request)
            get :show_request,
                :k => public_bodies(:geraldine_public_body).api_key,
                :id => info_request.id

            response.should be_success
            assigns[:request].id.should == info_request.id
            r = ActiveSupport::JSON.decode(response.body)
            r['title'].should == info_request.title
        end
    end

    # GET /api/v2/body/:id/request_events.:feed_type
    describe 'showing public body info' do
        it 'should show an Atom feed of new request events' do
            get :body_request_events,
                :id => public_bodies(:geraldine_public_body).id,
                :k => public_bodies(:geraldine_public_body).api_key,
                :feed_type => 'atom'

            response.should be_success
            response.should render_template('api/request_events')
            assigns[:events].size.should > 0
            assigns[:events].each do |event|
                event.info_request.public_body.should == public_bodies(:geraldine_public_body)
                event.outgoing_message.should_not be_nil
                event.event_type.should satisfy { |x| ['sent', 'followup_sent', 'resent', 'followup_resent'].include?(x) }
            end
        end

        it 'should show a JSON feed of new request events' do
            get :body_request_events,
                :id => public_bodies(:geraldine_public_body).id,
                :k => public_bodies(:geraldine_public_body).api_key,
                :feed_type => 'json'

            response.should be_success
            assigns[:events].size.should > 0
            assigns[:events].each do |event|
                event.info_request.public_body.should == public_bodies(:geraldine_public_body)
                event.outgoing_message.should_not be_nil
                event.event_type.should satisfy {|x| ['sent', 'followup_sent', 'resent', 'followup_resent'].include?(x)}
            end

            assigns[:event_data].size.should == assigns[:events].size
            assigns[:event_data].each do |event_record|
                event_record[:event_type].should satisfy { |x| ['sent', 'followup_sent', 'resent', 'followup_resent'].include?(x) }
            end
        end

        it 'should honour the since_event_id parameter' do
            get :body_request_events,
               :id => public_bodies(:geraldine_public_body).id,
               :k => public_bodies(:geraldine_public_body).api_key,
               :feed_type => 'json'

            response.should be_success
            first_event = assigns[:event_data][0]
            second_event_id = assigns[:event_data][1][:event_id]

            get :body_request_events,
                :id => public_bodies(:geraldine_public_body).id,
                :k => public_bodies(:geraldine_public_body).api_key,
                :feed_type => 'json',
                :since_event_id => second_event_id
            response.should be_success
            assigns[:event_data].should == [first_event]
        end

        it 'should honour the since_date parameter' do
            get :body_request_events,
                :id => public_bodies(:humpadink_public_body).id,
                :k => public_bodies(:humpadink_public_body).api_key,
                :since_date => '2010-01-01',
                :feed_type => 'atom'

            response.should be_success
            response.should render_template('api/request_events')
            assigns[:events].size.should > 0
            assigns[:events].each do |event|
                event.created_at.should >= Date.new(2010, 1, 1)
            end

            get :body_request_events,
                :id => public_bodies(:humpadink_public_body).id,
                :k => public_bodies(:humpadink_public_body).api_key,
                :since_date => '2010-01-01',
                :feed_type => 'json'
            assigns[:events].each do |event|
                event.created_at.should >= Date.new(2010, 1, 1)
            end
        end
    end
end
