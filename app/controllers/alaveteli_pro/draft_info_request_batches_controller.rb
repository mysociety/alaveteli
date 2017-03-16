class AlaveteliPro::DraftInfoRequestBatchesController < ApplicationController
  def create
    @draft = current_user.draft_info_request_batches.create(draft_params)
    @query = params[:authority_query]
    if request.xhr?
      respond_with_partial(@draft, @query)
    else
      redirect_after_create_or_update(@draft, @query)
    end
  end

  def update_bodies
    @draft = current_user.draft_info_request_batches.find(params[:id])
    if params[:add_body_id]
      @draft.public_bodies << PublicBody.find(params[:add_body_id])
    elsif params[:remove_body_id]
      @draft.public_bodies.delete(PublicBody.find(params[:remove_body_id]))
    end
    @query = params[:authority_query]
    if request.xhr?
      respond_with_partial(@draft, @query)
    else
      redirect_after_create_or_update(@draft, @query)
    end
  end

  private

  def redirect_after_create_or_update(draft, query)
    if query
      path = alaveteli_pro_batch_request_authority_searches_path(
        draft_id: draft.id,
        authority_query: query
      )
    else
      path = new_alaveteli_pro_batch_request_authority_search_path(
        draft_id: draft.id
      )
    end
    redirect_to path, notice: _('Your Batch Request has been saved!')
  end

  def respond_with_partial(draft, query)
    render :partial => 'summary',
           :layout => false,
           :locals => { :draft => draft, :authority_query => query }
  end

  def draft_params
    params.require(:alaveteli_pro_draft_info_request_batch).
      permit(:title, :body, :public_body_ids)
  end
end
