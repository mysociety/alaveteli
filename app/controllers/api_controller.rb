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

        request.set_described_state('waiting_response')

        # Return the URL and ID number.
        render :json => {
            'url' => make_url("request", request.url_title),
            'id'  => request.id
        }

    end

    def add_correspondence
        request = InfoRequest.find_by_id(params[:id])
        if request.nil?
            render :json => { "errors" => ["Could not find request #{params[:id]}"] }, :status => 404
            return
        end

        json = ActiveSupport::JSON.decode(params[:correspondence_json])
        attachments = params[:attachments]

        direction = json["direction"]
        body = json["body"]
        sent_at = json["sent_at"]

        errors = []

        if !request.is_external?
            render :json => { "errors" => ["Request #{params[:id]} cannot be updated using the API"] }, :status => 500
            return
        end

        if request.public_body_id != @public_body.id
            render :json => { "errors" => ["You do not own request #{params[:id]}"] }, :status => 500
            return
        end

        if !["request", "response"].include?(direction)
            errors << "The direction parameter must be 'request' or 'response'"
        end

        if body.nil?
            errors << "The 'body' is missing"
        elsif body.empty?
            errors << "The 'body' is empty"
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

            mail = RequestMailer.external_response(request, body, sent_at, attachment_hashes)

            request.receive(mail, mail.encoded, true)
        end
        render :json => {
            'url' => make_url("request", request.url_title),
        }
    end

    def body_request_events
        feed_type = params[:feed_type]
        raise PermissionDenied.new("#{@public_body.id} != #{params[:id]}") if @public_body.id != params[:id].to_i

        since_date_str = params[:since_date]
        if since_date_str.nil?
            @events = InfoRequestEvent.find_by_sql([
              %(select info_request_events.*
                from info_requests
                join info_request_events on info_requests.id = info_request_events.info_request_id
                where info_requests.public_body_id = ?
                and info_request_events.event_type in (
                  'sent', 'followup_sent', 'resent', 'followup_resent'
                )
                order by info_request_events.created_at desc
              ), @public_body.id
            ])
        else
            begin
              since_date = Date.strptime(since_date_str, "%Y-%m-%d")
            rescue ArgumentError
              render :json => {"errors" => [
                      "Parameter since_date must be in format yyyy-mm-dd (not '#{since_date_str}')" ] },
                  :status => 500
              return
            end
            @events = InfoRequestEvent.find_by_sql([
              %(select info_request_events.*
                from info_requests
                join info_request_events on info_requests.id = info_request_events.info_request_id
                where info_requests.public_body_id = ?
                and info_request_events.event_type in (
                  'sent', 'followup_sent', 'resent', 'followup_resent'
                )
                and info_request_events.created_at >= ?
                order by info_request_events.created_at desc
              ), @public_body.id, since_date
            ])
        end
        if feed_type == "atom"
            render :template => "api/request_events.atom", :layout => false
        elsif feed_type == "json"
            # For the JSON feed, we take a "since" parameter that allows the client
            # to restrict to events more recent than a certain other event
            if params[:since_event_id]
                @since_event_id = params[:since_event_id].to_i
            end
            @event_data = []
            @events.each do |event|
                break if event.id == @since_event_id

                request = event.info_request
                this_event = {
                    :request_id => request.id,
                    :event_id => event.id,
                    :created_at => event.created_at.iso8601,
                    :event_type => event.event_type,
                    :request_url =>  request_url(request),
                    :request_email => request.incoming_email,
                    :title => request.title,
                    :body => event.outgoing_message.body,

                    :user_name => request.user_name,
                }
                if request.user
                    this_event[:user_url] = user_url(request.user)
                end

                @event_data.push(this_event)
            end
            render :json => @event_data
        else
            raise ActiveRecord::RecordNotFound.new("Unrecognised feed type: #{feed_type}")
        end
    end

    protected
    def check_api_key
        raise PermissionDenied.new("Missing required parameter 'k'") if params[:k].nil?
        @public_body = PublicBody.find_by_api_key(params[:k].gsub(' ', '+'))
        raise PermissionDenied if @public_body.nil?
    end

    private
    def make_url(*args)
        "http://" + AlaveteliConfiguration::domain + "/" + args.join("/")
    end
end
