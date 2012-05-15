# app/controllers/request_game_controller.rb:
# The 'categorise old requests' game
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_game_controller.rb,v 1.9 2009-10-19 22:06:54 francis Exp $

class RequestGameController < ApplicationController

    def play
        session[:request_game] = Time.now

        old = InfoRequest.find_old_unclassified(:conditions => ["prominence = 'normal'"])
        @missing = old.size
        @total = InfoRequest.count
        @done = @total - @missing
        @percentage = (@done.to_f / @total.to_f * 10000).round / 100.0

        @requests = old.sort_by{ rand }.slice(0..2)

        if @missing == 0
            flash[:notice] = _('<p>All done! Thank you very much for your help.</p><p>There are <a href="{{helpus_url}}">more things you can do</a> to help {{site_name}}.</p>',
                :helpus_url => help_credits_path+"#helpus",
                :site_name => site_name)
        end

        @league_table_28_days = InfoRequestEvent.make_league_table(
            [ "event_type = 'status_update' and created_at >= ?", Time.now() - 28.days ]
        )[0..10]
        @league_table_all_time = InfoRequestEvent.make_league_table(
            [ "event_type = 'status_update'"]
        )[0..10]
        @play_urls = true
    end

    def show
        url_title = params[:url_title]
        if !authenticated?(
                :web => _("To play the request categorisation game"),
                :email => _("Then you can play the request categorisation game."),
                :email_subject => _("Play the request categorisation game")
            )
            # do nothing - as "authenticated?" has done the redirect to signin page for us
            return
        end
        redirect_to show_request_url(:url_title => url_title)
    end

    def stop
        session[:request_game] = nil
        flash[:notice] = _('Thank you for helping us keep the site tidy!')
        redirect_to frontpage_url
    end

end

