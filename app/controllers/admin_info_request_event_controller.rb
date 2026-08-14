# app/controllers/admin_info_request_event_controller.rb:
# Controller for FOI request event manipulation from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminInfoRequestEventController < AdminController
  include Admin::Searchable
  include Admin::Sortable

  before_action :set_info_request_event, only: [:edit, :update]

  sortable default: :updated_at_desc, relevance: :indexed_search?,
           only: [:index]

  def index
    @page = get_search_page_from_params
    @query = params[:query] || ""

    @info_request_events = measure_search(
      sorted(
        info_request_event_scope.
          order(id: :desc).
          paginate(page: @page, per_page: 100)
      )
    )
  end

  # used so due dates get fixed
  def update
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
  end

  private

  def set_info_request_event
    @info_request_event = InfoRequestEvent.find(params[:id])
  end

  def info_request_event_scope
    return base_scope if @query.blank?

    base_scope.search_scope(@query, backend: :postgresql, admin_mode: true)
  end

  def base_scope
    scope = InfoRequestEvent
    cannot?(:admin, AlaveteliPro::Embargo) ? scope.not_embargoed : scope
  end
end
