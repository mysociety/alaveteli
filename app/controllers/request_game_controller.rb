# app/controllers/request_game_controller.rb:
# The 'categorise old requests' game
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_game_controller.rb,v 1.7 2009-10-14 22:10:45 francis Exp $

class RequestGameController < ApplicationController
    
    def play
        session[:request_game] = Time.now

        old = InfoRequest.find_old_unclassified(:conditions => ["prominence = 'normal'"])
        @missing = old.size
        @total = InfoRequest.count
        @percentage = ((@total - @missing).to_f / @total.to_f * 10000).round / 100.0

        @requests = old.sort_by{ rand }.slice(0..2)

        if @missing == 0
            flash[:notice] = 'All done! Thank you very much for your help.'
            redirect_to frontpage_url
        end

        # Work out league table
        status_update_events = InfoRequestEvent.find(:all, 
            :conditions => [ "event_type = 'status_update' and created_at >= ?", Time.now() - 28.days ])
        table = Hash.new { |h,k| h[k] = 0 }
        for event in status_update_events
            user_id = event.params[:user_id]
            table[user_id] += 1
        end
        @league_table = []
        for user_id, count in table
            user = User.find(user_id)
            @league_table.push([user, count])
        end
        @league_table.sort! { |a,b| b[1] <=> a[1] }

        @play_urls = true
    end

    def show
        url_title = params[:url_title]
        if !authenticated?(
                :web => "To play the request categorisation game",
                :email => "Then you can play the request categorisation game.", 
                :email_subject => "Play the request categorisation game"
            )
            # do nothing - as "authenticated?" has done the redirect to signin page for us
            return
        end
        redirect_to show_request_url(:url_title => url_title)
    end

    def stop
        session[:request_game] = nil
        flash[:notice] = 'Thank you for helping us keep the site tidy!'
        redirect_to frontpage_url
    end

end

