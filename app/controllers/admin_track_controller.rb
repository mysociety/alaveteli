# -*- encoding : utf-8 -*-
# app/controllers/admin_track_controller.rb:
# Show email alerts / RSS feeds from admin interface.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminTrackController < AdminController

    def index
        @query = params[:query]
        if @query
          track_things = TrackThing.where(["lower(track_query) like lower('%'||?||'%')", @query])
        else
          track_things = TrackThing
        end
        @admin_tracks = track_things.paginate :order => "created_at desc", :page => params[:page], :per_page => 100
        @popular = ActiveRecord::Base.connection.select_all("select count(*) as count, title, info_request_id from track_things join info_requests on info_request_id = info_requests.id where info_request_id is not null group by info_request_id, title order by count desc limit 10;")
    end

    def destroy
        track_thing = TrackThing.find(params[:id].to_i)
        track_thing.destroy
        flash[:notice] = 'Track destroyed'
        redirect_to admin_user_url(track_thing.tracking_user)
    end

    private

end
