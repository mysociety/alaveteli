# -*- encoding : utf-8 -*-
class AdminPublicBodyChangeRequestsController < AdminController

  def edit
    @change_request = PublicBodyChangeRequest.find(params[:id])
  end

  def update
    @change_request = PublicBodyChangeRequest.find(params[:id])
    @change_request.close!
    if params[:subject] && params[:response]
      @change_request.send_response(params[:subject], params[:response])
      flash[:notice] = 'The change request has been closed and the user has been notified'
    else
      flash[:notice] = 'The change request has been closed'
    end
    redirect_to admin_general_index_path
  end

end
