require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

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
        geraldine = public_bodies(:geraldine_public_body)
        number_of_requests = InfoRequest.count(:conditions => ["public_body_id = ?", geraldine.id])
        
        request_data = {
            "title" => "Tell me about your chickens",
            "body" => "Dear Sir,\n\nI should like to know about your chickens.\n\nYours in faith,\nBob\n",
            
            "external_url" => "http://www.example.gov.uk/foi/chickens_23",
            "external_user_name" => "Bob Smith",
        }
        
        post :create_request, :k => geraldine.api_key, :request_json => request_data.to_json
        response.should be_success

        response.content_type.should == "application/json"
        
        response_body = ActiveSupport::JSON.decode(response.body)
        response_body["errors"].should be_nil
        response_body["url"].should =~ /^http/
        
        InfoRequest.count(:conditions => ["public_body_id = ?", geraldine.id]).should == number_of_requests + 1
        
        new_request = InfoRequest.find(response_body["id"])
        new_request.user_id.should be_nil
        new_request.external_user_name.should == request_data["external_user_name"]
        new_request.external_url.should == request_data["external_url"]
        
        new_request.title.should == request_data["title"]
        new_request.last_event_forming_initial_request.outgoing_message.body.should == request_data["body"].strip
        
        new_request.public_body_id.should == geraldine.id
    end
    
    it "should add a response to a request" do
        geraldine = public_bodies(:geraldine_public_body)
        
        # First we need to create a request
        post :create_request, :k => geraldine.api_key, :request_json => {
                "title" => "Tell me about your chickens",
                "body" => "Dear Sir,\n\nI should like to know about your chickens.\n\nYours in faith,\nBob\n",
                
                "external_url" => "http://www.example.gov.uk/foi/chickens_23",
                "external_user_name" => "Bob Smith",
            }.to_json
        response.content_type.should == "application/json"
        request_id = ActiveSupport::JSON.decode(response.body)["id"]
        IncomingMessage.count(:conditions => ["info_request_id = ?", request_id]).should == 0
        
        # Now add a response
        sent_at = "2012-05-28T12:35:39+01:00"
        response_body = "Thank you for your request for information, which we are handling in accordance with the Freedom of Information Act 2000. You will receive a response within 20 working days or before the next full moon, whichever is sooner.\n\nYours sincerely,\nJohn Gandermulch,\nExample Council FOI Officer\n"
        post :add_correspondence, :k => geraldine.api_key, :id => request_id, :correspondence_json => {
                "direction" => "response",
                "sent_at" => sent_at,
                "body" => response_body
            }.to_json
        
        response.should be_success
        incoming_messages = IncomingMessage.all(:conditions => ["info_request_id = ?", request_id])
        incoming_messages.count.should == 1
        incoming_message = incoming_messages[0]
        
        incoming_message.sent_at.should == Time.iso8601(sent_at)
        incoming_message.get_main_body_text_folded.should == response_body
    end
    
    it "should allow attachments to be uploaded" do
        
    end
    
    it "should show information about a request" do
        
    end
end
