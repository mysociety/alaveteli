# -*- encoding : utf-8 -*-
# app/controllers/request_game_controller.rb:
# The 'categorise old requests' game
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class RequestGameController < ApplicationController

  def play
    session[:request_game] = Time.zone.now

    @missing = InfoRequest.
      where_old_unclassified.
        is_searchable.
          count
    @total = InfoRequest.count
    @done = @total - @missing
    @percentage = if @total > 0
      (@done.to_f / @total.to_f * 10000).round / 100.0
    else
      100.0
    end
    @requests = InfoRequest.
      includes(:public_body, :user).
        where_old_unclassified.
          limit(3).
            is_searchable.
              order('random()')

    if @missing == 0
      flash.now[:notice] = {
        :partial => "request_game/game_over.html.erb",
        :locals => {
          :helpus_url => help_credits_path(:anchor => "helpus"),
          :site_name => site_name
        }
      }
    end

    @league_table_28_days = RequestClassification.league_table(10,
      [ "created_at >= ?", Time.zone.now - 28.days ])
    @league_table_all_time = RequestClassification.league_table(10)
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
