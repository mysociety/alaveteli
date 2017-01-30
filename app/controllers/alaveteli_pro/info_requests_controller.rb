# -*- encoding : utf-8 -*-
# app/controllers/alaveteli_pro/info_requests_controller.rb
# Controller for info requests
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::InfoRequestsController < AlaveteliPro::BaseController
  before_filter :set_draft
  before_filter :set_public_body, only: [:new]
  before_filter :load_data_from_draft, only: [:preview, :create]

  def index
    @request_filter = RequestFilter.new
    if params[:request_filter]
      @request_filter.update_attributes(request_filter_params)
    end
    info_requests = @request_filter.results(current_user)
    @page = params[:page] || 1
    @per_page = 10
    @info_requests = info_requests.paginate :page => @page,
                                            :per_page => @per_page

  end

  def new
    if @draft_info_request
      load_data_from_draft
    else
      create_initial_objects
    end
  end

  def preview
    if all_models_valid?
      render "preview"
    else
      show_errors
    end
  end

  def create
    if all_models_valid?
      @info_request.save # Saves @outgoing_message too
      @embargo.save if @embargo.present?
      send_initial_message(@outgoing_message)
      destroy_draft
      redirect_to show_alaveteli_pro_request_path(
        url_title: @info_request.url_title)
    else
      show_errors
    end
  end

  def update
    @info_request = InfoRequest.find(params[:id])
    authorize! :update_request_state, @info_request
    new_status = info_request_params[:described_state]
    @info_request.set_described_state(new_status, current_user)
    flash[:notice] = _("Your request has been updated!")
    redirect_to show_alaveteli_pro_request_path(
      url_title: @info_request.url_title)
  end

  private

  def show_errors
    # There'll be a duplicate error if the outgoing_message is invalid, so
    # delete it
    @info_request.errors.delete(:outgoing_messages)
    render "new"
  end


  def all_models_valid?
    @info_request.valid? && @outgoing_message.valid? && \
    (@embargo.nil? || @embargo.present? && @embargo.valid?)
  end

  def set_draft
    if params[:draft_id]
      @draft_info_request = current_user.draft_info_requests.find(
        params[:draft_id]
      )
    end
  end

  def set_public_body
    if params[:public_body]
      @public_body = PublicBody.find_by_url_name(params[:public_body])
    end
  end

  def load_data_from_draft
    @info_request = InfoRequest.from_draft(@draft_info_request)
    @outgoing_message = @info_request.outgoing_messages.first
    @embargo = @info_request.embargo
  end

  def create_initial_objects
    @draft_info_request = DraftInfoRequest.new(public_body: @public_body)
    @info_request = InfoRequest.new(public_body: @public_body)
    @outgoing_message = OutgoingMessage.new(info_request: @info_request)
    # TODO: set duration based on current user's account settings
    @embargo = Embargo.new(info_request: @info_request)
  end

  def destroy_draft
    if params[:draft_id]
      current_user.draft_info_requests.destroy(params[:draft_id])
    end
  end

  def send_initial_message(outgoing_message)
    if outgoing_message.sendable?
      mail_message = OutgoingMailer.initial_request(
        outgoing_message.info_request,
        outgoing_message
      ).deliver

      outgoing_message.record_email_delivery(
        mail_message.to_addrs.join(', '),
        mail_message.message_id
      )
    end
  end

  def request_filter_params
    params.require(:request_filter).permit(:filter, :order, :search)
  end

  def info_request_params
    params.require(:info_request).permit(:described_state)
  end
end
