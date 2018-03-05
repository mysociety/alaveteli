# -*- encoding : utf-8 -*-
# app/controllers/alaveteli_pro/info_request_batches_controller.rb
# Controller for batch info requests
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::InfoRequestBatchesController < AlaveteliPro::BaseController
  before_filter :check_users_batch_allowance, only: [:preview, :create]

  def new
    @draft_info_request_batch = load_draft
    load_data_from_draft(@draft_info_request_batch)
    render 'alaveteli_pro/info_requests/new'
  end

  def preview
    @draft_info_request_batch = load_draft
    load_data_from_draft(@draft_info_request_batch)
    if all_models_valid?
      render 'alaveteli_pro/info_requests/preview'
    else
      remove_duplicate_errors
      render 'alaveteli_pro/info_requests/new'
    end
  end

  def create
    @draft_info_request_batch = load_draft
    load_data_from_draft(@draft_info_request_batch)
    if all_models_valid?
      @info_request_batch.save
      @draft_info_request_batch.destroy
      redirect_to show_alaveteli_pro_batch_request_path(id: @info_request_batch.id)
    else
      remove_duplicate_errors
      render 'alaveteli_pro/info_requests/new'
    end
  end

  private

  def check_users_batch_allowance
    unless (current_user.pro_account &&
            current_user.pro_account.batches_remaining > 0)
      flash[:error] = _('Sorry you have exceeded your current batch allowance')
      redirect_to \
        new_alaveteli_pro_info_request_batch_path(draft_id: params[:draft_id])
      return false
    end
  end

  def load_draft
    current_user.draft_info_request_batches.find(params[:draft_id])
  end

  def load_data_from_draft(draft)
    @info_request_batch = InfoRequestBatch.from_draft(draft)
    # We make an example request mainly so that we can get the outgoing message
    # from it, as well as the embargo object. The outgoing message will have
    # a templated body from our template, allowing us to present a more
    # realistic preview to the user.
    # We can also use these objects to validate the batch, checking that it
    # will create valid requests against the constraints they have on subject
    # lines and body content.
    @example_info_request = @info_request_batch.example_request
    @embargo = @example_info_request.embargo
    # if no title or embargo has been set, assume this is an initial draft
    # rather than an edit in progress and apply a default embargo
    if @info_request_batch.title.blank? && !@embargo
      # TODO: set duration based on current user's account settings
      @embargo = AlaveteliPro::Embargo.new(info_request: @example_info_request)
    end

    @outgoing_message = @example_info_request.outgoing_messages.first
  end

  def all_models_valid?
    @example_info_request.valid? && \
    @outgoing_message.valid? && \
    (@embargo.nil? || @embargo.present? && @embargo.valid?) && \
    @info_request_batch.valid?
  end

  def remove_duplicate_errors
    # Tidy up the errors because there will be duplicates
    # When there's an error on the outgoing messages, it will also appear on
    # the request, so remove that version
    @example_info_request.errors.delete(:outgoing_messages)
    # If these have errors, the example info_request will too, and they'll be
    # better messages, so we show them instead.
    @info_request_batch.errors.delete(:title)
    @info_request_batch.errors.delete(:body)
  end
end
