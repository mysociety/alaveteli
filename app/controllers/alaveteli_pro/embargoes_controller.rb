# -*- encoding : utf-8 -*-
# app/controllers/alaveteli_pro/embargoes_controller.rb
# Controller for embargoes
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::EmbargoesController < AlaveteliPro::BaseController
  def destroy
    @embargo = AlaveteliPro::Embargo.find(params[:id])
    authorize! :update, @embargo
    @info_request = @embargo.info_request
    # Embargoes cannot be updated individually on batch requests
    if @info_request.info_request_batch_id
      raise PermissionDenied
    end
    if @embargo.destroy
      @info_request.log_event('expire_embargo', {})
      flash[:notice] = _("Your request is now public!")
    else
      flash[:error] = _("Sorry, something went wrong publishing your " \
                        "request, please try again.")
    end
    return redirect_to request_url(@info_request)
  end

  def destroy_batch
    @info_request_batch = InfoRequestBatch.find(
      params[:info_request_batch_id])
    authorize! :update, @info_request_batch
    info_request_ids = @info_request_batch.info_requests.pluck(:id)
    embargoes = AlaveteliPro::Embargo.where(info_request_id: info_request_ids)
    if embargoes.destroy_all
      @info_request_batch.embargo_duration = nil
      @info_request_batch.save!
      @info_request_batch.log_event('expire_embargo', {})
      flash[:notice] = _("Your requests are now public!")
    else
      flash[:error] = _("Sorry, something went wrong publishing your " \
                        "requests, please try again.")
    end
    if params[:info_request_id]
      @info_request = InfoRequest.find(params[:info_request_id])
      redirect_to show_alaveteli_pro_request_path(
        url_title: @info_request.url_title)
    else
      redirect_to show_alaveteli_pro_batch_request_path(@info_request_batch)
    end
  end
end
