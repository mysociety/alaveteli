# -*- encoding : utf-8 -*-
# app/controllers/widget_controller.rb:
# Handle widgets, if enabled
#
# Copyright (c) 2014 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class WidgetsController < ApplicationController

  before_filter :check_widget_config, :find_info_request, :check_prominence
  skip_before_filter :set_x_frame_options_header, :only => [:show]

  def show
    medium_cache
    @track_thing = TrackThing.create_track_for_request(@info_request)
    @status = @info_request.calculate_status
    @count = @info_request.track_things.count + @info_request.widget_votes.count + 1
    @user_owns_request = @info_request.user && @info_request.user == @user

    @existing_track =
    if @user
      TrackThing.find_existing(@user, @track_thing)
    end

    @existing_vote =
    unless @existing_track
      @info_request.
        widget_votes.
          where(:cookie => cookies[:widget_vote]).
            any?
    end

    render :action => 'show', :layout => false
  end

  def new
    long_cache
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
