# app/controllers/track_controller.rb:
# Publically visible email alerts and RSS - think an alert system crossed with
# social bookmarking.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: track_controller.rb,v 1.24 2008-08-08 20:44:54 francis Exp $

class TrackController < ApplicationController

    # Track all updates to a particular request
    def track_request
        @info_request = InfoRequest.find_by_url_title(params[:url_title])
        @track_thing = TrackThing.create_track_for_request(@info_request)

        return atom_feed_internal if params[:feed] == 'feed'

        ret = self.track_set
        if ret
            flash[:notice] = "You are " + ret + " tracking this request!"
            redirect_to request_url(@info_request)
        end
    end

    # Track all new/successful requests
    def track_list
        @view = params[:view]

        if @view.nil?
            @track_thing = TrackThing.create_track_for_all_new_requests
        elsif @view == 'successful'
            @track_thing = TrackThing.create_track_for_all_successful_requests
        else
            raise "unknown request list view " + @view.to_s
        end

        return atom_feed_internal if params[:feed] == 'feed'

        ret = self.track_set
        if ret
            if @view.nil?
                if ret == 'already'
                    flash[:notice] = "You are already being told about any new requests!"
                elsif ret == 'now'
                    flash[:notice] = "You will now be told about any new requests!"
                else 
                    raise "unknown ret '" + ret + "'"
                end
            elsif @view == 'successful'
                if ret == 'already'
                    flash[:notice] = "You are already being told about any successful requests!"
                elsif ret == 'now'
                    flash[:notice] = "You will now be told about any successful requests!"
                else 
                    raise "unknown ret '" + ret + "'"
                end
            else
                raise "unknown request list view " + @view.to_s
            end
            redirect_to request_list_url(:view => @view)
        end
    end

    # Track all updates to a particular public body
    def track_public_body
        @public_body = PublicBody.find_by_url_name(params[:url_name])
        @track_thing = TrackThing.create_track_for_public_body(@public_body)

        return atom_feed_internal if params[:feed] == 'feed'

        ret = self.track_set
        if ret
            flash[:notice] = "You are " + ret + " tracking this public authority!"
            redirect_to public_body_url(@public_body)
        end
    end

    # Track a user
    def track_user
        @track_user = User.find_by_url_name(params[:url_name])
        @track_thing = TrackThing.create_track_for_user(@track_user)

        return atom_feed_internal if params[:feed] == 'feed'

        ret = self.track_set
        if ret
            flash[:notice] = "You are " + ret + " tracking this person!"
            redirect_to user_url(@track_user)
        end
    end

    # Track a search term
    def track_search_query
        # XXX should be better thing in rails routes than having to do this
        # join just to get / and . to work in a query.
        query_array = params[:query_array]
        @query = query_array.join("/")
        @track_thing = TrackThing.create_track_for_search_query(@query)

        return atom_feed_internal if params[:feed]

        ret = self.track_set
        if ret
            flash[:notice] = "You are " + ret + " tracking the search '" + CGI.escapeHTML(@query) + "' !"
            redirect_to search_url(@query)
        end
    end

    # Generic request tracker - set @track_thing before calling
    def track_set
        if @user
            @existing_track = TrackThing.find_by_existing_track(@user, @track_thing)
            if @existing_track
                return "already"
            end
        end

        if not authenticated?(@track_thing.params)
            return false
        end

        @track_thing.track_medium = 'email_daily'
        @track_thing.tracking_user_id = @user.id
        @track_thing.save!

        return "now"
    end 

    # Atom feed (like RSS) for the track
    def atom_feed
        @track_thing = TrackThing.find(params[:track_id].to_i)
        if @track_thing.track_medium != 'feed'
            raise "can only view feeds for feed tracks, not email ones"
        end
        atom_feed_internal
    end
    def atom_feed_internal
        @xapian_object = perform_search([InfoRequestEvent], @track_thing.track_query, @track_thing.params[:feed_sortby], nil, 25, 1) 
        respond_to do |format|
            format.atom { render :template => 'track/atom_feed' }
        end
    end

    # Change or delete a track
    def update
        track_thing = TrackThing.find(params[:track_id].to_i)

        if not authenticated_as_user?(track_thing.tracking_user,
                :web => "To cancel this alert",
                :email => "Then you can cancel the alert.",
                :email_subject => "Cancel a WhatDoTheyKnow alert"
            )
            # do nothing - as "authenticated?" has done the redirect to signin page for us
            return
        end

        STDOUT.puts(params.to_yaml)
        new_medium = params[:track_medium]
        if new_medium == 'delete'
            track_thing.destroy
            flash[:notice] = "You will no longer be emailed updates about " + track_thing.params[:list_description]
            redirect_to params[:r]
        # Reuse code like this if we let medium change again.
        #elsif new_medium == 'email_daily'
        #    track_thing.track_medium = new_medium
        #    track_thing.created_at = Time.now() # as created_at is used to limit the alerts to start with
        #    track_thing.save!
        #    flash[:notice] = "You are now tracking " + track_thing.params[:list_description] + " by email daily"
        #    redirect_to user_url(track_thing.tracking_user)
        else
            raise "new medium not handled " + new_medium
        end
    end

end
 
