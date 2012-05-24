# app/controllers/track_controller.rb:
# Publically visible email alerts and RSS - think an alert system crossed with
# social bookmarking.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: track_controller.rb,v 1.31 2009-09-02 14:18:26 francis Exp $

class TrackController < ApplicationController

    protect_from_forgery # See ActionController::RequestForgeryProtection for details

    before_filter :medium_cache

    # Track all updates to a particular request
    def track_request
        @info_request = InfoRequest.find_by_url_title(params[:url_title])
        @track_thing = TrackThing.create_track_for_request(@info_request)

        return atom_feed_internal if params[:feed] == 'feed'

        if self.track_set
            redirect_to request_url(@info_request)
        end
    end

    # Track all new/successful requests
    def track_list
        @view = params[:view]

        if @view == 'recent' || @view.nil? # the blank one for backwards compatibility
            @track_thing = TrackThing.create_track_for_all_new_requests
        elsif @view == 'successful'
            @track_thing = TrackThing.create_track_for_all_successful_requests
        else
            raise "unknown request list view " + @view.to_s
        end

        return atom_feed_internal if params[:feed] == 'feed'

        if self.track_set
            redirect_to request_list_url(:view => @view)
        end
    end

    # Track all updates to a particular public body
    def track_public_body
        @public_body = PublicBody.find_by_url_name_with_historic(params[:url_name])
        raise ActiveRecord::RecordNotFound.new("None found") if @public_body.nil?
        # If found by historic name, or alternate locale name, redirect to new name
        if  @public_body.url_name != params[:url_name]
            redirect_to track_public_body_url(:url_name => @public_body.url_name, :feed => params[:feed], :event_type => params[:event_type])
            return
        end

        if params[:event_type]
            @track_thing = TrackThing.create_track_for_public_body(@public_body, params[:event_type])
        else
            @track_thing = TrackThing.create_track_for_public_body(@public_body)
        end

        return atom_feed_internal if params[:feed] == 'feed'

        if self.track_set
            redirect_to public_body_url(@public_body)
        end
    end

    # Track a user
    def track_user
        @track_user = User.find_by_url_name(params[:url_name])
        raise ActiveRecord::RecordNotFound.new("No such user") if @track_user.nil?
        @track_thing = TrackThing.create_track_for_user(@track_user)

        return atom_feed_internal if params[:feed] == 'feed'

        if self.track_set
            redirect_to user_url(@track_user)
        end
    end

    # Track a search term
    def track_search_query
        # XXX should be better thing in rails routes than having to do this
        # join just to get / and . to work in a query.
        query_array = params[:query_array]
        @query = query_array.join("/")

        # XXX more hackery to make alternate formats still work with query_array
        if /^(.*)\.json$/.match(@query)
            @query = $1
            params[:format] = "json"
        end

        @track_thing = TrackThing.create_track_for_search_query(@query)

        return atom_feed_internal if params[:feed] == 'feed'

        if self.track_set
            if @query.scan("variety").length == 1
                # we're making a track for a simple filter, for which
                # there's an expression in the UI (rather than relying
                # on index:value strings in the query)
                if @query =~ /variety:user/
                    postfix = "users"
                    @query.sub!("variety:user", "")
                elsif @query =~ /variety:authority/
                    postfix = "bodies"
                    @query.sub!("variety:authority", "")
                elsif @query =~ /variety:sent/
                    postfix = "requests"
                    @query.sub!("variety:sent", "")
                end
                @query.strip!
            end
            redirect_to search_url([@query, postfix])
        end
    end

    # Generic request tracker - set @track_thing before calling
    def track_set
        if @user
            @existing_track = TrackThing.find_by_existing_track(@user, @track_thing)
            if @existing_track
                flash[:notice] = _("You are already following updates about {{track_description}}", :track_description => @track_thing.params[:list_description])
                return true
            end
        end

        if not authenticated?(@track_thing.params)
            return false
        end

        @track_thing.track_medium = 'email_daily'
        @track_thing.tracking_user_id = @user.id
        @track_thing.save!
        if @user.receive_email_alerts
            flash[:notice] = _('You will now be emailed updates about {{track_description}}. <a href="{{change_email_alerts_url}}">Prefer not to receive emails?</a>', :track_description =>  @track_thing.params[:list_description], :change_email_alerts_url => url_for(:controller => "user", :action => "wall", :url_name => @user.url_name))
        else
            flash[:notice] = _('You are now <a href="{{wall_url_user}}">following</a> updates about {{track_description}}', :track_description => @track_thing.params[:list_description], :wall_url_user => url_for(:controller => "user", :action => "wall", :url_name => @user.url_name))
        end
        return true
    end

    # Old-Style atom track. We're phasing this out, so for now issue a
    # 301 Redirect. Most aggregators should honour this, but we should
    # keep an eye on the logs to see which ones are still used before
    # deleting this (or for safety, we may wish to move them to a new
    # table)
    def atom_feed
        @track_thing = TrackThing.find(params[:track_id].to_i)
        if @track_thing.track_medium != 'feed'
            raise "can only view feeds for feed tracks, not email ones"
        end
        redirect_to do_track_url(@track_thing, 'feed'), :status => :moved_permanently
    end

    def atom_feed_internal
        @xapian_object = perform_search([InfoRequestEvent], @track_thing.track_query, @track_thing.params[:feed_sortby], nil, 25, 1)
        respond_to do |format|
            format.atom { render :template => 'track/atom_feed' }
            format.json { render :json => @xapian_object.results.map { |r| r[:model].json_for_api(true,
                    lambda { |t| @template.highlight_and_excerpt(t, @xapian_object.words_to_highlight, 150) }
                ) } }
        end
    end

    # Change or delete a track
    def update
        track_thing = TrackThing.find(params[:track_id].to_i)

        if not authenticated_as_user?(track_thing.tracking_user,
                :web => _("To cancel this alert"),
                :email => _("Then you can cancel the alert."),
                :email_subject => _("Cancel a {{site_name}} alert",:site_name=>site_name)
            )
            # do nothing - as "authenticated?" has done the redirect to signin page for us
            return
        end

        new_medium = params[:track_medium]
        if new_medium == 'delete'
            track_thing.destroy
            flash[:notice] = _("You are no longer following {{track_description}}", :track_description => track_thing.params[:list_description])
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

    # Remove all tracks of a certain type (e.g. requests / users / bodies)
    def delete_all_type
        user_id = User.find(params[:user].to_i)

        if not authenticated_as_user?(user_id,
                :web => _("To cancel these alerts"),
                :email => _("Then you can cancel the alerts."),
                :email_subject => _("Cancel some {{site_name}} alerts",:site_name=>site_name)
            )
            # do nothing - as "authenticated?" has done the redirect to signin page for us
            return
        end

        track_type = params[:track_type]

        flash[:notice] = _("You will no longer be emailed updates for those alerts")
        for track_thing in TrackThing.find(:all, :conditions => [ "track_type = ? and tracking_user_id = ?", track_type, user_id ])
            track_thing.destroy
        end
        flash[:notice] += "</ul>"

        redirect_to params[:r]
    end


end

