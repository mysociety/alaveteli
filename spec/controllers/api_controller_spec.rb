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
      expect(InfoRequest.count).to eq(@number_of_requests)
    end

    it 'should check the API key' do
      expect {
        post :create_request,
        :k => 'This is not really an API key',
        :request_json => @request_data.to_json
      }.to raise_error ApplicationController::PermissionDenied
      expect(InfoRequest.count).to eq(@number_of_requests)
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
    expect(response.content_type).to eq('application/json')
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
      expect(response).to be_success

      expect(response.content_type).to eq('application/json')
      response_body = ActiveSupport::JSON.decode(response.body)
      expect(response_body['errors']).to be_nil
      expect(response_body['url']).to match(/^http/)

      expect(InfoRequest.count(:conditions => [
                          'public_body_id = ?',
                        public_bodies(:geraldine_public_body).id]
                        )).to eq(number_of_requests + 1)

      new_request = InfoRequest.find(response_body['id'])
      expect(new_request.user_id).to be_nil
      expect(new_request.external_user_name).to eq(request_data['external_user_name'])
      expect(new_request.external_url).to eq(request_data['external_url'])

      expect(new_request.title).to eq(request_data['title'])
      expect(new_request.last_event_forming_initial_request.outgoing_message.body).to eq(request_data['body'].strip)

      expect(new_request.public_body_id).to eq(public_bodies(:geraldine_public_body).id)
      expect(new_request.info_request_events.size).to eq(1)
      expect(new_request.info_request_events[0].event_type).to eq('sent')
      expect(new_request.info_request_events[0].calculated_state).to eq('waiting_response')
    end
  end

  # POST /api/v2/request/:id/add_correspondence.json
  describe 'adding correspondence to a request' do
    it 'should add a response to a request' do
      # First we need an external request
      request_id = info_requests(:external_request).id

      # Initially it has no incoming messages
      expect(IncomingMessage.count(:conditions => ["info_request_id = ?", request_id])).to eq(0)

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
      expect(response).to be_success
      incoming_messages = IncomingMessage.all(:conditions => ['info_request_id = ?', request_id])
      expect(incoming_messages.count).to eq(1)
      incoming_message = incoming_messages[0]

      expect(incoming_message.sent_at).to eq(Time.iso8601(sent_at))
      expect(incoming_message.get_main_body_text_folded).to be_equal_modulo_whitespace_to(response_body)
    end

    it 'should add a followup to a request' do
      # First we need an external request
      request_id = info_requests(:external_request).id

      # Initially it has one outgoing message
      expect(OutgoingMessage.count(:conditions => ['info_request_id = ?', request_id])).to eq(1)

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
      expect(response).to be_success
      followup_messages = OutgoingMessage.all(
        :conditions => ["info_request_id = ? and message_type = 'followup'", request_id]
      )
      expect(followup_messages.size).to eq(1)
      followup_message = followup_messages[0]

      expect(followup_message.last_sent_at).to eq(Time.iso8601(sent_at))
      expect(followup_message.body).to eq(followup_body.strip)
    end

    it 'should update the status if a valid state is supplied' do
      # First we need an external request
      request_id = info_requests(:external_request).id

      # Initially it has no incoming messages
      expect(IncomingMessage.count(:conditions => ['info_request_id = ?', request_id])).to eq(0)

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
      expect(response).to be_success
      incoming_messages = IncomingMessage.all(:conditions => ['info_request_id = ?', request_id])
      expect(incoming_messages.count).to eq(1)
      request = InfoRequest.find_by_id(request_id)
      expect(request.described_state).to eq('successful')
    end

    it 'should raise a JSON 500 error if an invalid state is supplied' do
      # First we need an external request
      request_id = info_requests(:external_request).id

      # Initially it has no incoming messages
      expect(IncomingMessage.count(:conditions => ['info_request_id = ?', request_id])).to eq(0)

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
      expect(response.status).to eq(500)
      expect(ActiveSupport::JSON.decode(response.body)['errors']).to eq([
      "'random_string' is not a valid request state"])

      incoming_messages = IncomingMessage.all(:conditions => ['info_request_id = ?', request_id])
      expect(incoming_messages.count).to eq(0)
      request = InfoRequest.find_by_id(request_id)
      expect(request.described_state).to eq('waiting_response')
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

      expect(response.status).to eq(403)
      expect(ActiveSupport::JSON.decode(response.body)['errors']).to eq([
      "Request #{request_id} cannot be updated using the API"])

      expect(IncomingMessage.count).to eq(n_incoming_messages)
      expect(OutgoingMessage.count).to eq(n_outgoing_messages)
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

      expect(response.status).to eq(403)
      expect(ActiveSupport::JSON.decode(response.body)['errors']).to eq([
      "You do not own request #{request_id}"])

      expect(IncomingMessage.count).to eq(n_incoming_messages)
      expect(OutgoingMessage.count).to eq(n_outgoing_messages)
    end

    it 'should return a JSON 404 error for non-existent requests' do
      request_id = '123459876'
      allow(InfoRequest).to receive(:find_by_id).with(request_id).and_return(nil)
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
      expect(response.status).to eq(404)
      expect(ActiveSupport::JSON.decode(response.body)['errors']).to eq(['Could not find request 123459876'])
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
      expect(response.status).to eq(403)
      expect(ActiveSupport::JSON.decode(response.body)['errors']).to eq(["Request #{request_id} cannot be updated using the API"])
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
      expect(response.status).to eq(500)
      errors = ActiveSupport::JSON.decode(response.body)['errors']
      expect(errors).to eq(["You cannot attach files to messages in the 'request' direction"])
    end

    it 'should allow files to be attached to a response' do
      # First we need an external request
      request_id = info_requests(:external_request).id

      # Initially it has no incoming messages
      expect(IncomingMessage.count(:conditions => ['info_request_id = ?', request_id])).to eq(0)

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
      expect(response).to be_success
      incoming_messages = IncomingMessage.all(:conditions => ['info_request_id = ?', request_id])
      expect(incoming_messages.count).to eq(1)
      incoming_message = incoming_messages[0]

      expect(incoming_message.sent_at).to eq(Time.iso8601(sent_at))
      expect(incoming_message.get_main_body_text_folded).to be_equal_modulo_whitespace_to(response_body)

      # Get the attachment
      attachments = incoming_message.get_attachments_for_display
      expect(attachments.size).to eq(1)
      attachment = attachments[0]
      expect(attachment.filename).to eq('tfl.pdf')
      expect(attachment.body).to eq(load_file_fixture('tfl.pdf'))
    end
  end

  # POST /api/v2/request/:id/update.json
  describe 'updating a request\'s status' do
    it 'should update the status' do
      # First we need an external request
      request_id = info_requests(:external_request).id
      request = InfoRequest.find_by_id(request_id)

      # Its status should be the default for a new request
      expect(request.described_state).to eq('waiting_response')

      # Now accept an update
      post :update_state,
        :k => public_bodies(:geraldine_public_body).api_key,
        :id => request_id,
        :state => 'partially_successful'

      # It should have updated the status
      request = InfoRequest.find_by_id(request_id)
      expect(request.described_state).to eq('partially_successful')

      # It should have recorded the status_update event
      last_event = request.info_request_events.last
      expect(last_event.event_type).to eq('status_update')
      expect(last_event.described_state).to eq('partially_successful')
      expect(last_event.params_yaml).to match(/script: Geraldine Quango on behalf of requester via API/)
    end

    it 'should return a JSON 500 error if an invalid state is sent' do
      # First we need an external request
      request_id = info_requests(:external_request).id
      request = InfoRequest.find_by_id(request_id)

      # Its status should be the default for a new request
      expect(request.described_state).to eq('waiting_response')

      # Now post an invalid update
      post :update_state,
        :k => public_bodies(:geraldine_public_body).api_key,
        :id => request_id,
        :state => 'random_string'

      # Check that the error has been raised...
      expect(response.status).to eq(500)
      expect(ActiveSupport::JSON.decode(response.body)['errors']).to eq(["'random_string' is not a valid request state"])

      # ..and that the status hasn't been updated
      request = InfoRequest.find_by_id(request_id)
      expect(request.described_state).to eq('waiting_response')
    end

    it 'should return a JSON 404 error for non-existent requests' do
      request_id = '123459876'
      allow(InfoRequest).to receive(:find_by_id).with(request_id).and_return(nil)

      post :update_state,
        :k => public_bodies(:geraldine_public_body).api_key,
        :id => request_id,
        :state => "successful"

      expect(response.status).to eq(404)
      expect(ActiveSupport::JSON.decode(response.body)['errors']).to eq(['Could not find request 123459876'])
    end

    it 'should return a JSON 403 error if we try to add correspondence to a request we don\'t own' do
      request_id = info_requests(:naughty_chicken_request).id

      post :update_state,
        :k => public_bodies(:geraldine_public_body).api_key,
        :id => request_id,
        :state => 'successful'

      expect(response.status).to eq(403)
      expect(ActiveSupport::JSON.decode(response.body)['errors']).to eq(["Request #{request_id} cannot be updated using the API"])
    end
  end

  # GET /api/v2/request/:id.json
  describe 'showing request info' do
    it 'should show information about a request' do
      info_request = info_requests(:naughty_chicken_request)

      get :show_request,
        :k => public_bodies(:geraldine_public_body).api_key,
        :id => info_request.id

      expect(response).to be_success
      expect(assigns[:request].id).to eq(info_request.id)

      r = ActiveSupport::JSON.decode(response.body)
      expect(r['title']).to eq(info_request.title)
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

      expect(response).to be_success
      expect(assigns[:request].id).to eq(info_request.id)
      r = ActiveSupport::JSON.decode(response.body)
      expect(r['title']).to eq(info_request.title)
    end
  end

  # GET /api/v2/body/:id/request_events.:feed_type
  describe 'showing public body info' do
    it 'should show an Atom feed of new request events' do
      get :body_request_events,
        :id => public_bodies(:geraldine_public_body).id,
        :k => public_bodies(:geraldine_public_body).api_key,
        :feed_type => 'atom'

      expect(response).to be_success
      expect(response).to render_template('api/request_events')
      expect(assigns[:events].size).to be > 0
      assigns[:events].each do |event|
        expect(event.info_request.public_body).to eq(public_bodies(:geraldine_public_body))
        expect(event.outgoing_message).not_to be_nil
        expect(event.event_type).to satisfy { |x| ['sent', 'followup_sent', 'resent', 'followup_resent'].include?(x) }
      end
    end

    it 'should show a JSON feed of new request events' do
      get :body_request_events,
        :id => public_bodies(:geraldine_public_body).id,
        :k => public_bodies(:geraldine_public_body).api_key,
        :feed_type => 'json'

      expect(response).to be_success
      expect(assigns[:events].size).to be > 0
      assigns[:events].each do |event|
        expect(event.info_request.public_body).to eq(public_bodies(:geraldine_public_body))
        expect(event.outgoing_message).not_to be_nil
        expect(event.event_type).to satisfy {|x| ['sent', 'followup_sent', 'resent', 'followup_resent'].include?(x)}
      end

      expect(assigns[:event_data].size).to eq(assigns[:events].size)
      assigns[:event_data].each do |event_record|
        expect(event_record[:event_type]).to satisfy { |x| ['sent', 'followup_sent', 'resent', 'followup_resent'].include?(x) }
      end
    end

    it 'should honour the since_event_id parameter' do
      get :body_request_events,
        :id => public_bodies(:geraldine_public_body).id,
        :k => public_bodies(:geraldine_public_body).api_key,
        :feed_type => 'json'

      expect(response).to be_success
      first_event = assigns[:event_data][0]
      second_event_id = assigns[:event_data][1][:event_id]

      get :body_request_events,
        :id => public_bodies(:geraldine_public_body).id,
        :k => public_bodies(:geraldine_public_body).api_key,
        :feed_type => 'json',
        :since_event_id => second_event_id
      expect(response).to be_success
      expect(assigns[:event_data]).to eq([first_event])
    end

    it 'should honour the since_date parameter' do
      get :body_request_events,
        :id => public_bodies(:humpadink_public_body).id,
        :k => public_bodies(:humpadink_public_body).api_key,
        :since_date => '2010-01-01',
        :feed_type => 'atom'

      expect(response).to be_success
      expect(response).to render_template('api/request_events')
      expect(assigns[:events].size).to be > 0
      assigns[:events].each do |event|
        expect(event.created_at).to be >= Date.new(2010, 1, 1)
      end

      get :body_request_events,
        :id => public_bodies(:humpadink_public_body).id,
        :k => public_bodies(:humpadink_public_body).api_key,
        :since_date => '2010-01-01',
        :feed_type => 'json'
      assigns[:events].each do |event|
        expect(event.created_at).to be >= Date.new(2010, 1, 1)
      end
    end
  end
end
