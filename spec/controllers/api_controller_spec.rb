require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def normalise_whitespace(s)
    s = s.gsub(/^\s+|\s+$/, "")
    s = s.gsub(/\s+/, " ")
    return s
end

Spec::Matchers.define :be_equal_modulo_whitespace_to do |expected|
  match do |actual|
    normalise_whitespace(actual) == normalise_whitespace(expected)
  end
end

describe ApiController, "when using the API" do
    it "should check the API key" do
        request_data = {
            "title" => "Tell me about your chickens",
            "body" => "Dear Sir,\n\nI should like to know about your chickens.\n\nYours in faith,\nBob\n",
            
            "external_url" => "http://www.example.gov.uk/foi/chickens_23",
            "external_user_name" => "Bob Smith",
        }
        
        number_of_requests = InfoRequest.count
        expect {
            post :create_request, :k => "This is not really an API key", :request_json => request_data.to_json
        }.to raise_error ApplicationController::PermissionDenied
        
        InfoRequest.count.should == number_of_requests
    end
    
    it "should create a new request from a POST" do
        number_of_requests = InfoRequest.count(
            :conditions => [
                    "public_body_id = ?",
                    public_bodies(:geraldine_public_body).id
            ]
        )
        
        request_data = {
            "title" => "Tell me about your chickens",
            "body" => "Dear Sir,\n\nI should like to know about your chickens.\n\nYours in faith,\nBob\n",
            
            "external_url" => "http://www.example.gov.uk/foi/chickens_23",
            "external_user_name" => "Bob Smith",
        }
        
        post :create_request, :k => public_bodies(:geraldine_public_body).api_key, :request_json => request_data.to_json
        response.should be_success

        response.content_type.should == "application/json"
        
        response_body = ActiveSupport::JSON.decode(response.body)
        response_body["errors"].should be_nil
        response_body["url"].should =~ /^http/
        
        InfoRequest.count(:conditions => [
            "public_body_id = ?",
            public_bodies(:geraldine_public_body).id]
        ).should == number_of_requests + 1
        
        new_request = InfoRequest.find(response_body["id"])
        new_request.user_id.should be_nil
        new_request.external_user_name.should == request_data["external_user_name"]
        new_request.external_url.should == request_data["external_url"]
        
        new_request.title.should == request_data["title"]
        new_request.last_event_forming_initial_request.outgoing_message.body.should == request_data["body"].strip
        
        new_request.public_body_id.should == public_bodies(:geraldine_public_body).id
    end
    
    def _create_request
        post :create_request,
            :k => public_bodies(:geraldine_public_body).api_key,
            :request_json => {
                "title" => "Tell me about your chickens",
                "body" => "Dear Sir,\n\nI should like to know about your chickens.\n\nYours in faith,\nBob\n",
                
                "external_url" => "http://www.example.gov.uk/foi/chickens_23",
                "external_user_name" => "Bob Smith",
            }.to_json
        response.content_type.should == "application/json"
        return ActiveSupport::JSON.decode(response.body)["id"]
    end
    
    it "should add a response to a request" do
        # First we need an external request
        request_id = info_requests(:external_request).id
        
        # Initially it has no incoming messages
        IncomingMessage.count(:conditions => ["info_request_id = ?", request_id]).should == 0
        
        # Now add one
        sent_at = "2012-05-28T12:35:39+01:00"
        response_body = "Thank you for your request for information, which we are handling in accordance with the Freedom of Information Act 2000. You will receive a response within 20 working days or before the next full moon, whichever is sooner.\n\nYours sincerely,\nJohn Gandermulch,\nExample Council FOI Officer\n"
        post :add_correspondence,
            :k => public_bodies(:geraldine_public_body).api_key,
            :id => request_id,
            :correspondence_json => {
                "direction" => "response",
                "sent_at" => sent_at,
                "body" => response_body
            }.to_json
        
        # And make sure it worked
        response.should be_success
        incoming_messages = IncomingMessage.all(:conditions => ["info_request_id = ?", request_id])
        incoming_messages.count.should == 1
        incoming_message = incoming_messages[0]
        
        incoming_message.sent_at.should == Time.iso8601(sent_at)
        incoming_message.get_main_body_text_folded.should be_equal_modulo_whitespace_to(response_body)
    end

    it "should add a followup to a request" do
        # First we need an external request
        request_id = info_requests(:external_request).id
        
        # Initially it has one outgoing message
        OutgoingMessage.count(:conditions => ["info_request_id = ?", request_id]).should == 1
        
        # Add another, as a followup
        sent_at = "2012-05-29T12:35:39+01:00"
        followup_body = "Pls answer ASAP.\nkthxbye\n"
        post :add_correspondence,
            :k => public_bodies(:geraldine_public_body).api_key,
            :id => request_id,
            :correspondence_json => {
                "direction" => "request",
                "sent_at" => sent_at,
                "body" => followup_body
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
    
    it "should not allow internal requests to be updated" do
        n_incoming_messages = IncomingMessage.count
        n_outgoing_messages = OutgoingMessage.count
        
        expect {
            post :add_correspondence,
                :k => public_bodies(:geraldine_public_body).api_key,
                :id => info_requests(:naughty_chicken_request).id,
                :correspondence_json => {
                    "direction" => "request",
                    "sent_at" => Time.now.iso8601,
                    "body" => "xxx"
                }.to_json
        }.to raise_error ActiveRecord::RecordNotFound
        
        IncomingMessage.count.should == n_incoming_messages
        OutgoingMessage.count.should == n_outgoing_messages
    end
    
    it "should not allow other people’s requests to be updated" do
        request_id = _create_request
        n_incoming_messages = IncomingMessage.count
        n_outgoing_messages = OutgoingMessage.count
        
        expect {
            post :add_correspondence,
                :k => public_bodies(:humpadink_public_body).api_key,
                :id => request_id,
                :correspondence_json => {
                    "direction" => "request",
                    "sent_at" => Time.now.iso8601,
                    "body" => "xxx"
                }.to_json
        }.to raise_error ActiveRecord::RecordNotFound
        
        IncomingMessage.count.should == n_incoming_messages
        OutgoingMessage.count.should == n_outgoing_messages
    end
    
    it "should not allow files to be attached to a followup" do
        post :add_correspondence,
            :k => public_bodies(:geraldine_public_body).api_key,
            :id => info_requests(:external_request).id,
            :correspondence_json => {
                    "direction" => "request",
                    "sent_at" => Time.now.iso8601,
                    "body" => "Are you joking, or are you serious?"
                }.to_json,
            :attachments => [
                fixture_file_upload("files/tfl.pdf")
            ]
            
        
        # Make sure it worked
        response.status.to_i.should == 500
        errors = ActiveSupport::JSON.decode(response.body)["errors"]
        errors.should == ["You cannot attach files to messages in the 'request' direction"]
    end
    
    it "should allow files to be attached to a response" do
        # First we need an external request
        request_id = info_requests(:external_request).id
        
        # Initially it has no incoming messages
        IncomingMessage.count(:conditions => ["info_request_id = ?", request_id]).should == 0
        
        # Now add one
        sent_at = "2012-05-28T12:35:39+01:00"
        response_body = "Thank you for your request for information, which we are handling in accordance with the Freedom of Information Act 2000. You will receive a response within 20 working days or before the next full moon, whichever is sooner.\n\nYours sincerely,\nJohn Gandermulch,\nExample Council FOI Officer\n"
        post :add_correspondence,
            :k => public_bodies(:geraldine_public_body).api_key,
            :id => request_id,
            :correspondence_json => {
                    "direction" => "response",
                    "sent_at" => sent_at,
                    "body" => response_body
                }.to_json,
            :attachments => [
                fixture_file_upload("files/tfl.pdf")
            ]
        
        # And make sure it worked
        response.should be_success
        incoming_messages = IncomingMessage.all(:conditions => ["info_request_id = ?", request_id])
        incoming_messages.count.should == 1
        incoming_message = incoming_messages[0]
        
        incoming_message.sent_at.should == Time.iso8601(sent_at)
        incoming_message.get_main_body_text_folded.should be_equal_modulo_whitespace_to(response_body)
        
        # Get the attachment
        attachments = incoming_message.get_attachments_for_display
        attachments.size.should == 1
        attachment = attachments[0]
        
        attachment.filename.should == "tfl.pdf"
        attachment.body.should == load_file_fixture("tfl.pdf")
    end
    
    it "should show information about a request" do
        info_request = info_requests(:naughty_chicken_request)
        get :show_request,
            :k => public_bodies(:geraldine_public_body).api_key,
            :id => info_request.id
        
        response.should be_success
        assigns[:request].id.should == info_request.id
        
        r = ActiveSupport::JSON.decode(response.body)
        r["title"].should == info_request.title
        # Let’s not test all the fields here, because it would
        # essentially just be a matter of copying the code that
        # assigns them and changing assignment to an equality
        # check, which does not really test anything at all.
    end
end
