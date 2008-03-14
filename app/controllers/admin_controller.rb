# app/controllers/admin_controller.rb:
# Controller for admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_controller.rb,v 1.3 2008-03-14 11:08:41 francis Exp $

class AdminController < ApplicationController
    layout "admin"

    def index
        @user_count = User.count
        @public_body_count = PublicBody.count
        @info_request_count = InfoRequest.count

        @events_title = "Events in last week"
        date_back_to = Time.now - 1.week
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
    end
end

