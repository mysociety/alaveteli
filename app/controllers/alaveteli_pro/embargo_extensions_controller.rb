# -*- encoding : utf-8 -*-
# app/controllers/alaveteli_pro/embargo_extensions_controller.rb
# Controller for embargo extensions
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::EmbargoExtensionsController < AlaveteliPro::BaseController
  def create
    @embargo = AlaveteliPro::Embargo.find(
      embargo_extension_params[:embargo_id])
    authorize! :update, @embargo
    @info_request = @embargo.info_request
    # Embargoes cannot be updated individually on batch requests
    if @info_request.info_request_batch_id
      raise PermissionDenied
    end
    unless @embargo.expiring_soon?
      raise PermissionDenied
    end
    @embargo_extension = AlaveteliPro::EmbargoExtension.new(
      embargo_extension_params)
    if @embargo_extension.save
      @embargo.extend(@embargo_extension)
      flash[:notice] = _("Your request will now be private " \
                         "until {{expiry_date}}.",
                         expiry_date: I18n.l(
                           @embargo.publish_at, format: '%d %B %Y'))
    else
      flash[:error] = _("Sorry, something went wrong updating your " \
                        "request's privacy settings, please try again.")
    end
    redirect_to show_alaveteli_pro_request_path(
        url_title: @info_request.url_title)
  end

  def create_batch
    @info_request_batch = InfoRequestBatch.find(
      params[:info_request_batch_id])
    authorize! :update, @info_request_batch
    begin
      ActiveRecord::Base.transaction do
        @info_request_batch.info_requests.each do |info_request|
          info_request.embargo.extend(
            AlaveteliPro::EmbargoExtension.create!(
              embargo_id: info_request.embargo.id,
              extension_duration: params[:extension_duration]
            )
          )
        end
      end
      publish_at = @info_request_batch.info_requests.first.embargo.publish_at
      flash[:notice] = _("Your requests will now be private " \
                         "until {{expiry_date}}.",
                         expiry_date: I18n.l(publish_at, format: '%d %B %Y'))
    rescue ActiveRecord::RecordInvalid
      flash[:error] = _("Sorry, something went wrong updating your " \
                        "requests' privacy settings, please try again.")
    end
    if params[:info_request_id]
      @info_request = InfoRequest.find(params[:info_request_id])
      redirect_to show_alaveteli_pro_request_path(
        url_title: @info_request.url_title)
    else
      redirect_to show_alaveteli_pro_batch_request_path(@info_request_batch)
    end
  end

  private

  def embargo_extension_params
    params.
      require(:alaveteli_pro_embargo_extension).
      permit(:embargo_id, :extension_duration)
  end
end
