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
