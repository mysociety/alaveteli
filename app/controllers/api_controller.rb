class ApiController < ApplicationController
    before_filter :check_api_key
    
    def show_request
        @request = InfoRequest.find(params[:id])
        raise PermissionDenied if @request.public_body_id != @public_body.id
        
        @request_data = {
            :id => @request.id,
            :url => make_url("request", @request.url_title),
            :title => @request.title,
            
            :created_at => @request.created_at,
            :updated_at => @request.updated_at,
            
            :status => @request.calculate_status,
            
            :public_body_url => make_url("body", @request.public_body.url_name),
            :requestor_url => make_url("user", @request.user.url_name),
            :request_email => @request.incoming_email,
            
            :request_text => @request.last_event_forming_initial_request.outgoing_message.body,
        }
        
        render :json => @request_data
    end
    
    def create_request
        json = ActiveSupport::JSON.decode(params[:request_json])
        existing_request = InfoRequest.find_by_existing_request(json["title"], 
                                                                @public_body.id, 
                                                                json["body"])
        info_request = InfoRequest.new(:title => json["title"],
                                       :public_body_id => @public_body.id,
                                       :described_state => "awaiting_response",
                                       :external_user_name => json["external_user_name"],
                                       :external_url => json["external_url"])
        outgoing_message = OutgoingMessage.new(json["body"])
        info_request.outgoing_messages << outgoing_messages
        outgoing_message.info_request = info_request
        # See if values were valid or not
        if !existing_request.nil? || !info_request.valid?
            # We don't want the error "Outgoing messages is invalid", as the outgoing message
            # will be valid for a specific reason which we are displaying anyway.
            info_request.errors.delete("outgoing_messages")
            render :json => {'errors' => :info_request.errors.to_s}
        else
            render :json => {'url' => 'http://goo.com'}
        end
    end
    
    def add_correspondence
        
    end
    
    protected
    def check_api_key
        @public_body = PublicBody.find_by_api_key(params[:k].gsub(' ', '+'))
        raise PermissionDenied if @public_body.nil?
    end
    
    private
    def make_url(*args)
        "http://" + MySociety::Config.get("DOMAIN", '127.0.0.1:3000') + "/" + args.join("/")
    end
end
