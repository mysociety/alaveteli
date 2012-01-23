# app/controllers/admin_controller.rb:
# Controller for main admin pages.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_general_controller.rb,v 1.12 2009-10-03 01:28:33 francis Exp $

class AdminGeneralController < AdminController
    def index
        # ensure we have a trailing slash
        current_uri = request.env['REQUEST_URI']
        if params[:suppress_redirect].nil? && !(current_uri =~ /\/$/)
            redirect_to admin_general_index_url + "/"
            return
        end

        # Overview counts of things
        @public_body_count = PublicBody.count

        @info_request_count = InfoRequest.count
        @outgoing_message_count = OutgoingMessage.count
        @incoming_message_count = IncomingMessage.count

        @user_count = User.count
        @track_thing_count = TrackThing.count

        @comment_count = Comment.count

        # Tasks to do
        @requires_admin_requests = InfoRequest.find(:all, :select => '*, ' + InfoRequest.last_event_time_clause + ' as last_event_time', :conditions => ["described_state = 'requires_admin'"], :order => "last_event_time")
        @error_message_requests = InfoRequest.find(:all, :select => '*, ' + InfoRequest.last_event_time_clause + ' as last_event_time', :conditions => ["described_state = 'error_message'"], :order => "last_event_time")
        @blank_contacts = PublicBody.find(:all, :conditions => ["request_email = ''"], :order => "updated_at")
        @old_unclassified = InfoRequest.find_old_unclassified(:limit => 20, 
                                                                       :conditions => ["prominence = 'normal'"])
        @holding_pen_messages = InfoRequest.holding_pen_request.incoming_messages
    end

    def timeline
        # Recent events
        @events_title = "Events in last two days"
        date_back_to = Time.now - 2.days
        if params[:hour]
            @events_title = "Events in last hour"
            date_back_to = Time.now - 1.hour
        end
        if params[:day]
            @events_title = "Events in last day"
            date_back_to = Time.now - 1.day
        end
        if params[:week]
            @events_title = "Events in last week"
            date_back_to = Time.now - 1.week
        end
        if params[:month]
            @events_title = "Events in last month"
            date_back_to = Time.now - 1.month
        end
        if params[:all]
            @events_title = "Events, all time"
            date_back_to = Time.now - 1000.years
        end
        @events = InfoRequestEvent.find(:all, :order => "created_at desc, id desc",
                :conditions => ["created_at > ? ", date_back_to.getutc])
        @public_body_history = PublicBody.versioned_class.find(:all, :order => "updated_at desc, id desc",
                :conditions => ["updated_at > ? ", date_back_to.getutc])
        for pbh in @public_body_history
            pbh.created_at = pbh.updated_at
        end
        @events += @public_body_history

        @events.sort! { |a,b| b.created_at <=> a.created_at }
    end

    def stats
        @request_by_state = InfoRequest.count(:group => 'described_state')
        @tracks_by_type = TrackThing.count(:group => 'track_type')
    end

    def debug
        @current_commit = `git log -1 --format="%H"`
        @current_branch = `git branch | grep "\*" | awk '{print $2}'`
        repo = `git remote show origin -n | grep Fetch | awk '{print $3}' | sed -re 's/.*:(.*).git/\\1/'`
        @github_origin = "https://github.com/#{repo.strip}/tree/"
        @request_env = request.env 
    end
end

