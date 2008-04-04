# app/controllers/track_controller.rb:
# Publically visible email alerts and RSS - think an alert system crossed with
# social bookmarking.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: track_controller.rb,v 1.3 2008-04-04 01:59:40 francis Exp $

class TrackController < ApplicationController

    # Track all updates to a particular request
    def track_request
        @info_request = InfoRequest.find_by_url_title(params[:url_title])
        @track_thing = TrackThing.create_track_for_request(@info_request)
        ret = self.track_set
        if ret
            flash[:notice] = "You are " + ret + " tracking this request!"
            redirect_to request_url(@info_request)
        end
    end

    # Generic request tracker - set @track_thing before calling
    def track_set
        if @user
            @existing_track = TrackThing.find_by_existing_track(@user.id, @track_thing.track_query)
            if @existing_track
                return "already"
            end
        end

        @track_thing.track_medium = 'email_daily'

        @title = @track_thing.params[:title]
        if params[:track_thing]
            @track_thing.track_medium = params[:track_thing][:track_medium]
        end

        if not params[:submitted_track] or not @track_thing.valid?
            render :template => 'track/track_set'
            return false
        end
        
        if not authenticated?(@track_thing.params)
            return false
        end

        @track_thing.tracking_user_id = @user.id
        @track_thing.save!

        return "now"
    end 

end
 
