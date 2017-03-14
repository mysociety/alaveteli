# -*- encoding : utf-8 -*-
# app/controllers/alaveteli_pro/info_request_batches_controller.rb
# Controller for batch info requests
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::InfoRequestBatchesController < AlaveteliPro::BaseController
  def new
    @draft_info_request_batch = load_draft
    load_data_from_draft
  end

  private

  def load_draft
    current_user.draft_info_request_batches.find(params[:draft_id])
  end

  def load_data_from_draft
    @info_request_batch = InfoRequestBatch.from_draft(@draft_info_request)
    @outgoing_message = @info_request_batch.outgoing_messages.first
    @embargo = @info_request_batch.embargo
  end
end
