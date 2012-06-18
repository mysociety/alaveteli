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
        request = InfoRequest.new(
            :title => json["title"],
            :public_body_id => @public_body.id,
            :described_state => "waiting_response",
            :external_user_name => json["external_user_name"],
            :external_url => json["external_url"]
        )
        
        outgoing_message = OutgoingMessage.new(
            :status => 'ready',
            :message_type => 'initial_request',
            :body => json["body"],
            :last_sent_at => Time.now(),
            :what_doing => 'normal_sort',
            :info_request => request
        )
        request.outgoing_messages << outgoing_message
        
        # Return an error if the request is invalid
        # (Can this ever happen?)
        if !request.valid?
            render :json => {
                'errors' => request.errors.full_messages
            }
            return
        end
        
        # Save the request, and add the corresponding InfoRequestEvent
        request.save!
        request.log_event("sent",
            :api => true,
            :email => nil,
            :outgoing_message_id => outgoing_message.id,
            :smtp_message_id => nil
        )
        
        # Return the URL and ID number.
        render :json => {
            'url' => make_url("request", request.url_title),
            'id'  => request.id
        }
        
    end
    
    def add_correspondence
        request = InfoRequest.find(params[:id])
        json = ActiveSupport::JSON.decode(params[:correspondence_json])
        attachments = params[:attachments]
        
        direction = json["direction"]
        body = json["body"]
        sent_at_str = json["sent_at"]
        
        errors = []
        
        if !request.is_external?
            raise ActiveRecord::RecordNotFound.new("Request #{params[:id]} cannot be updated using the API")
        end
        
        if request.public_body_id != @public_body.id
            raise ActiveRecord::RecordNotFound.new("You do not own request #{params[:id]}")
        end
        
        if !["request", "response"].include?(direction)
            errors << "The direction parameter must be 'request' or 'response'"
        end
        
        if body.nil?
            errors << "The 'body' is missing"
        elsif body.empty?
            errors << "The 'body' is empty"
        end
        
        begin
            sent_at = Time.iso8601(sent_at_str)
        rescue ArgumentError
            errors << "Failed to parse 'sent_at' field as ISO8601 time: #{sent_at_str}"
        end
        
        if direction == "request" && !attachments.nil?
            errors << "You cannot attach files to messages in the 'request' direction"
        end
        
        if !errors.empty?
            render :json => { "errors" => errors }, :status => 500
            return
        end
        
        if direction == "request"
            # In the 'request' direction, i.e. what we (Alaveteli) regard as outgoing
            
            outgoing_message = OutgoingMessage.new(
                :info_request => request,
                :status => 'ready',
                :message_type => 'followup',
                :body => body,
                :last_sent_at => sent_at,
                :what_doing => 'normal_sort'
            )
            request.outgoing_messages << outgoing_message
            request.save!
            request.log_event("followup_sent",
                :api => true,
                :email => nil,
                :outgoing_message_id => outgoing_message.id,
                :smtp_message_id => nil
            )
        else
            # In the 'response' direction, i.e. what we (Alaveteli) regard as incoming
            attachment_hashes = []
            (attachments || []).each_with_index do |attachment, i|
                filename = File.basename(attachment.original_filename)
                attachment_body = attachment.read
                content_type = AlaveteliFileTypes.filename_and_content_to_mimetype(filename, attachment_body) || 'application/octet-stream'
                attachment_hashes.push(
                    :content_type => content_type,
                    :body => attachment_body,
                    :filename => filename
                )
            end
            
            mail = RequestMailer.create_external_response(request, body, sent_at, attachment_hashes)
            request.receive(mail, mail.encoded, true)
        end
        
        head :no_content
    end
    
    protected
    def check_api_key
        raise "Missing required parameter 'k'" if params[:k].nil?
        @public_body = PublicBody.find_by_api_key(params[:k].gsub(' ', '+'))
        raise PermissionDenied if @public_body.nil?
    end
    
    private
    def make_url(*args)
        "http://" + MySociety::Config.get("DOMAIN", '127.0.0.1:3000') + "/" + args.join("/")
    end
end
