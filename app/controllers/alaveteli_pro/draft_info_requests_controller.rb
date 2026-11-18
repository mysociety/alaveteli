# app/controllers/alaveteli_pro/draft_info_requests_controller.rb
# Controller for draft info requests
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::DraftInfoRequestsController < AlaveteliPro::BaseController
  include AlaveteliPro::DraftRequestForm

  def create
    @draft = current_user.draft_info_requests.new(draft_params)

    if @draft.save
      redirect_after_save
    else
      render_form_with_errors
    end
  end

  def update
    @draft = current_user.draft_info_requests.find(params[:id])

    if @draft.update(draft_params)
      redirect_after_save
    else
      render_form_with_errors
    end
  end

  private

  def redirect_after_save
    if params[:preview]
      redirect_to preview_new_alaveteli_pro_info_request_path(draft_id: @draft.id)
    else
      redirect_to new_alaveteli_pro_info_request_path(draft_id: @draft.id),
                  notice: _("Your draft has been saved!")
    end
  end

  def render_form_with_errors
    load_form_from_draft(@draft)
    @info_request.errors.merge!(@draft.errors)
    render 'alaveteli_pro/info_requests/new', status: :unprocessable_entity
  end

  def draft_params
    info_request_params.merge(outgoing_message_params.merge(embargo_params))
  end

  def info_request_params
    params.require(:info_request).permit(:title, :public_body_id)
  end

  def outgoing_message_params
    params.require(:outgoing_message).permit(:body)
  end

  def embargo_params
    params.require(:embargo).permit(:embargo_duration)
  end
end
