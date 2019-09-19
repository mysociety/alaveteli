# -*- encoding : utf-8 -*-
# Does not inherit from AlaveteliPro::BaseController as is pre-login
class AlaveteliPro::AccountRequestController < ApplicationController
  before_action :set_in_pro_area

  def index
    @public_beta = true
  end

  def new
    render :index
  end

  def create
    @account_request = AlaveteliPro::AccountRequest.new(params[:account_request])
    if @account_request.valid?
      AlaveteliPro::AccountMailer.account_request(@account_request).deliver_now
      flash[:notice] = _("Thanks for your interest in {{pro_site_name}}, we'll get back to you soon!",
                         pro_site_name: AlaveteliConfiguration.pro_site_name)
      redirect_to frontpage_url
    else
      render 'index'
    end
  end

  private

  def set_in_pro_area
    @in_pro_area = true
  end
end

