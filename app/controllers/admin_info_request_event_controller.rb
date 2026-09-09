# app/controllers/admin_info_request_event_controller.rb:
# Controller for FOI request event manipulation from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminInfoRequestEventController < AdminController
  before_action :set_info_request_event, only: [:edit, :update]

  def index
    @page = params[:page] || 1
    @query = params[:query] || ""
    @info_request_events = InfoRequestEvent.
      order(id: :desc).
        paginate(page: @page, per_page: 100)

    if @query != ""
      @info_request_events =@info_request_events.
        search_scope(@query,
                     backend: :postgresql,
                     admin_mode: true)
    end
  end

  def edit
    @params_to_show = JSON.pretty_generate(@info_request_event.params)
  end

  # used so due dates get fixed
  def update
    @was_clarification = params[:commit] == "Was clarification request"

    if @was_clarification
      if @info_request_event.event_type != 'response'
        raise "can only mark responses as requires clarification"
      end

      @info_request_event.described_state = 'waiting_clarification'
      @info_request_event.calculated_state = 'waiting_clarification'
      # TODO: deliberately don't update described_at so doesn't reenter search?
      @info_request_event.save!
      # Reset the due dates for the request if necessary
      @info_request_event.recheck_due_dates

      flash[:notice] = "Old response marked as having been a request for clarification"
      redirect_to admin_request_url(@info_request_event.info_request)
    else
      @params_to_show = params.dig(:info_request_event, :params_to_show)

      if @params_to_show.strip.empty?
        raise "Event params cannot be empty"
      end
      begin
        @info_request_event.params = JSON.parse(@params_to_show)

        @info_request_event.save!
        flash[:notice] = "InfoRequestEvent params updated"
        redirect_to admin_info_request_events_path
      rescue JSON::ParserError => e
        flash[:error] = "Invalid JSON content: #{e.message}"
        render :edit, status: :unprocessable_entity
      end

    end
  end

  private

  def set_info_request_event
    @info_request_event = InfoRequestEvent.find(params[:id])
  end
end
