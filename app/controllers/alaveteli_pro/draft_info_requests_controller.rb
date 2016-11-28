# -*- encoding : utf-8 -*-
# app/controllers/alaveteli_pro/draft_info_requests_controller.rb
# Controller for draft info requests
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::DraftInfoRequestsController < AlaveteliPro::BaseController
  def create
    @draft = current_user.draft_info_requests.create(draft_params)
    redirect_after_create_or_update
  end

  def update
    @draft = current_user.draft_info_requests.find(params[:id])
    @draft.update_attributes(draft_params)
    redirect_after_create_or_update
  end

  private

  def redirect_after_create_or_update
    if params[:preview]
      redirect_to preview_new_alaveteli_pro_info_request_path(draft_id: @draft.id)
    else
      redirect_to new_alaveteli_pro_info_request_path(draft_id: @draft.id),
                  notice: _("Your draft has been saved!")
    end
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
