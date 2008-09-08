# app/controllers/admin_controller.rb:
# Controller for admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_controller.rb,v 1.20 2008-09-08 01:49:57 francis Exp $

class AdminController < ApplicationController
    layout "admin"
    before_filter :assign_http_auth_user

    def index
        # Overview counts of things
        @user_count = User.count
        @public_body_count = PublicBody.count
        @info_request_count = InfoRequest.count
        @track_thing_count = TrackThing.count
        @comment_count = Comment.count

        # Tasks to do
        last_event_time_clause = '(select created_at from info_request_events where info_request_events.info_request_id = info_requests.id order by created_at desc limit 1)'
        @requires_admin_requests = InfoRequest.find(:all, :select => '*, ' + last_event_time_clause + ' as last_event_time', :conditions => ["described_state = 'requires_admin'"], :order => "last_event_time")
        @blank_contacts = PublicBody.find(:all, :conditions => ["request_email = ''"], :order => "updated_at")
        @ten_days_old_unclassified = InfoRequest.find(:all, :select => '*, ' + last_event_time_clause + ' as last_event_time', :conditions => [ "awaiting_description = ? and " + last_event_time_clause + " < ? and prominence != 'backpage'", true, Time.now() - 10.days ], :order => "last_event_time")
        @holding_pen_messages = InfoRequest.holding_pen_request.incoming_messages
    end

    def timeline
        # Recent events
        @events_title = "Events in last two days"
        date_back_to = Time.now - 2.days
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
                :conditions => ["created_at > ? ", date_back_to])
        @public_body_history = PublicBody.versioned_class.find(:all, :order => "updated_at desc, id desc",
                :conditions => ["updated_at > ? ", date_back_to])
        for pbh in @public_body_history
            pbh.created_at = pbh.updated_at
        end
        @events += @public_body_history

        @events.sort! { |a,b| b.created_at <=> a.created_at }
    end

    def stats
        @request_by_state = InfoRequest.count(:group => 'described_state')
        @tracks_by_type = TrackThing.count(:group => 'track_type')
        @tracks_by_medium = TrackThing.count(:group => 'track_medium')
    end

    def debug
        @request_env = request.env 
    end
end

