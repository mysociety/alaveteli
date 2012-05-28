require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApiController, "when using the API" do
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
    end
end
