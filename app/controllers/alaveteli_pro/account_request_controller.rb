# -*- encoding : utf-8 -*-
# Does not inherit from AlaveteliPro::BaseController as is pre-login
class AlaveteliPro::AccountRequestController < ApplicationController

  def new
  end

  def create
    @account_request = AlaveteliPro::AccountRequest.new(params[:account_request])
    if @account_request.valid?
      AlaveteliPro::AccountMailer.account_request(@account_request)
      flash[:notice] = _("Thanks for your interest in {{pro_site_name}}, we'll get back to you soon!",
                         pro_site_name: AlaveteliConfiguration.pro_site_name)
      redirect_to frontpage_url
    else
      render 'new'
    end
  end

end

