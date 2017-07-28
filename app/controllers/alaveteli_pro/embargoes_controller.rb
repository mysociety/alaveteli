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
      flash[:notice] = _("Your request is now public!")
    else
      flash[:error] = _("Sorry, something went wrong publishing your " \
                        "request, please try again.")
    end
    return redirect_to request_url(@info_request)
  end
end
