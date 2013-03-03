# app/controllers/admin_track_controller.rb:
# Show email alerts / RSS feeds from admin interface.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/

class AdminTrackController < AdminController
    def list
        @query = params[:query]
        if @query
          track_things = TrackThing.where(["lower(track_query) like lower('%'||?||'%')", @query])
        else
          track_things = TrackThing
        end
        @admin_tracks = track_things.paginate :order => "created_at desc", :page => params[:page], :per_page => 100
    end

    private

end
