# -*- encoding : utf-8 -*-
# app/controllers/alaveteli_pro/info_requests_controller.rb
# Controller for info requests
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::InfoRequestsController < AlaveteliPro::BaseController
  before_filter :set_draft
  before_filter :load_data_from_draft, only: [:preview, :create]

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
      redirect_to show_request_path(url_title: @info_request.url_title)
    else
      show_errors
    end
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

  def load_data_from_draft
    @info_request = InfoRequest.from_draft(@draft_info_request)
    @outgoing_message = @info_request.outgoing_messages.first
    @embargo = @info_request.embargo
  end

  def create_initial_objects
    @draft_info_request = DraftInfoRequest.new
    @info_request = InfoRequest.new
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
end