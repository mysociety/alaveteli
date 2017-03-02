class AlaveteliPro::DraftInfoRequestBatchesController < ApplicationController
  def create
    @draft = current_user.draft_info_request_batches.create(draft_params)
    redirect_after_create_or_update(@draft)
  end

  def update
    @draft = current_user.draft_info_request_batches.find(params[:id])
    @draft.update_attributes(draft_params)
    redirect_after_create_or_update(@draft)
  end

  private

  def redirect_after_create_or_update(draft)
    if params[:query]
      path = alaveteli_pro_batch_request_authority_searches_path(draft_id: draft.id, query: params[:query])
    else
      path = new_alaveteli_pro_batch_request_authority_search_path(draft_id: draft.id)
    end
    redirect_to path, notice: _('Your Batch Request has been saved!')
  end

  def draft_params
    params.require(:alaveteli_pro_draft_info_request_batch).
      permit(:title, :body, :public_body_ids => [])
  end

end
