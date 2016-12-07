# -*- encoding : utf-8 -*-
# app/controllers/alaveteli_pro/embargo_extensions_controller.rb
# Controller for embargo extensions
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::EmbargoExtensionsController < AlaveteliPro::BaseController
  def create
    @embargo = Embargo.find(embargo_extension_params[:embargo_id])
    authorize! :update, @embargo
    @info_request = @embargo.info_request
    @embargo_extension = EmbargoExtension.new(embargo_extension_params)
    if @embargo_extension.save
      @embargo.extend(@embargo_extension)
      flash[:notice] = _("Your Embargo has been extended! It will now " \
                         "expire on {{expiry_date}}.",
                         expiry_date: @embargo.publish_at.to_date)
    else
      flash[:error] = _("Sorry, something went wrong extending your " \
                        "embargo, please try again.")
    end
    redirect_to show_alaveteli_pro_request_path(
        url_title: @info_request.url_title)
  end

  private

  def embargo_extension_params
    params.require(:embargo_extension).permit(:embargo_id, :extension_duration)
  end
end
