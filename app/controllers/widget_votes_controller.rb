# -*- encoding : utf-8 -*-
# app/controllers/widget_votes_controller.rb:
# Handle widget votes, if enabled
#
# Copyright (c) 2014 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'securerandom'

class WidgetVotesController < ApplicationController

  before_filter :check_widget_config, :find_info_request, :check_prominence

  # Track interest in a request from a non-logged in user
  def create
    unless @user
      cookie = cookies[:widget_vote]

      if cookie.nil?
        cookies.permanent[:widget_vote] = SecureRandom.hex(10)
        cookie = cookies[:widget_vote]
      end

      @info_request.widget_votes.
        where(:cookie => cookie).
          first_or_create
    end

    track_thing = TrackThing.create_track_for_request(@info_request)
    redirect_to do_track_path(track_thing), status => :temporary_redirect
  end

  private

  def check_widget_config
    unless AlaveteliConfiguration::enable_widgets
      raise ActiveRecord::RecordNotFound.new("Page not enabled")
    end
  end

  def find_info_request
    @info_request = InfoRequest.find(params[:request_id])
  end

  def check_prominence
    unless @info_request.prominence == 'normal'
      render :nothing => true, :status => :forbidden
    end
  end

end
