# -*- encoding : utf-8 -*-
class AlaveteliPro::DraftInfoRequestBatchesController < ApplicationController
  include AlaveteliPro::BatchRequest

  def create
    @draft = current_user.draft_info_request_batches.create(draft_params)
    respond_or_redirect(@draft)
  end

  def update
    @draft = current_user.draft_info_request_batches.find(params[:id])
    @draft.update_attributes(draft_params_multiple_bodies)
    if params[:preview]
      redirect_to preview_new_alaveteli_pro_info_request_batch_path(draft_id: @draft.id)
    else
      redirect_to new_alaveteli_pro_info_request_batch_path(draft_id: @draft.id),
                  notice: _("Your draft has been saved!")
    end
  end

  def update_bodies
    @draft = current_user.draft_info_request_batches.
      find_by(id: update_bodies_params[:draft_id])
    case update_bodies_params[:action]
    when 'add-all'
      @draft ||= current_user.draft_info_request_batches.create
      requestable = PublicBody.with_tag(category_tag).select(&:is_requestable?)
      @draft.public_bodies << requestable
    when 'add'
      public_body = PublicBody.find(update_bodies_params[:public_body_id])
      @draft ||= current_user.draft_info_request_batches.create
      @draft.public_bodies << public_body
    when 'remove'
      public_body = PublicBody.find(update_bodies_params[:public_body_id])
      raise ActiveRecord::RecordNotFound unless @draft
      @draft.public_bodies.delete(public_body)
      @draft.destroy! if @draft.public_bodies.empty?
    end
    respond_or_redirect(@draft)
  end

  private

  def respond_or_redirect(draft)
    @query = params[:authority_query]
    @page = params[:page]
    if request.xhr?
      respond_with_partial(@draft, @query, @page)
    else
      redirect_after_create_or_update_bodies(@draft, @query, @page)
    end
  end

  def redirect_after_create_or_update_bodies(draft, query, page)
    redirect_params = { mode: mode,
                        category_tag: category_tag }

    if query
      redirect_params[:authority_query] = query
      redirect_params[:page] = page
    end

    if draft.persisted?
      redirect_params[:draft_id] = draft.id
      flash[:notice] = _('Your Batch Request has been saved!')
    end

    path =
      alaveteli_pro_batch_request_authority_searches_path(redirect_params)

    redirect_to path
  end

  def respond_with_partial(draft, query, page)
    render partial: 'summary',
           layout: false,
           locals: { draft: draft,
                     query: query,
                     page: page,
                     mode: mode,
                     category_tag: category_tag }
  end

  # #create and #update accept an array of public_body_ids, whereas
  # #update_bodies only take a single body to add or remove, hence the two
  # different params.
  def draft_params
    params.require(:alaveteli_pro_draft_info_request_batch).
      permit(:title, :body, :embargo_duration, :public_body_ids, )
  end

  def draft_params_multiple_bodies
    params.require(:alaveteli_pro_draft_info_request_batch).
      permit(:title, :body, :embargo_duration, :public_body_ids => [])
  end

  def update_bodies_params
    params.require(:alaveteli_pro_draft_info_request_batch).
      permit(:draft_id, :public_body_id, :action)
  end
end
