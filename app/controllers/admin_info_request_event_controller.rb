# -*- encoding : utf-8 -*-
# app/controllers/admin_info_request_event_controller.rb:
# Controller for FOI request event manipulation from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminInfoRequestEventController < AdminController

  before_filter :set_info_request_event, :only => [:update]

  # used so due dates get fixed
  def update
    if @info_request_event.event_type != 'response'
      raise "can only mark responses as requires clarification"
    end
    @info_request_event.described_state = 'waiting_clarification'
    @info_request_event.calculated_state = 'waiting_clarification'
    # TODO: deliberately don't update described_at so doesn't reenter search?
    @info_request_event.save!

    flash[:notice] = "Old response marked as having been a clarification"
    redirect_to admin_request_url(@info_request_event.info_request)
  end

  private

  def set_info_request_event
    @info_request_event = InfoRequestEvent.find(params[:id])
  end

end
