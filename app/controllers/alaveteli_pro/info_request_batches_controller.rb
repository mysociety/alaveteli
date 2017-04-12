# -*- encoding : utf-8 -*-
# app/controllers/alaveteli_pro/info_request_batches_controller.rb
# Controller for batch info requests
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::InfoRequestBatchesController < AlaveteliPro::BaseController
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
