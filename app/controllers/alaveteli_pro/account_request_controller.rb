# Does not inherit from AlaveteliPro::BaseController as is pre-login
class AlaveteliPro::AccountRequestController < ApplicationController
  before_action :set_in_pro_area

  before_action :check_pro_pricing,
                only: :create, if: -> { feature_enabled?(:pro_pricing) }

  before_action :authenticate, :grant_pro_access,
                only: :create, if: -> { feature_enabled?(:pro_self_serve) }

  def index
    @title =
      _('FOI Management Tools for journalists, campaigners and researchers')
  end

  def create
    @account_request = AlaveteliPro::AccountRequest.new(
      params[:account_request]
    )

    if @account_request.valid?
      AlaveteliPro::AccountMailer.account_request(@account_request).deliver_now
      flash[:notice] = _('Thanks for your interest in {{pro_site_name}}, ' \
                         "we'll get back to you soon!",
                         pro_site_name: pro_site_name)
      redirect_to frontpage_url
    else
      render 'index'
    end
  end

  private

  def set_in_pro_area
    @in_pro_area = true
  end

  def check_pro_pricing
    redirect_to pro_plans_path
  end

  def grant_pro_access
    current_user.add_role(:pro)

    flash[:new_pro_user] = true
    flash[:notice] = _('Welcome to {{pro_site_name}}!',
                       pro_site_name: AlaveteliConfiguration.pro_site_name)

    redirect_to alaveteli_pro_dashboard_path
  end

  def authenticate
    post_redirect_params = {
      web: _('To upgrade your account'),
      email: _('Then you can upgrade your account'),
      email_subject: _('To upgrade your account')
    }

    authenticated?(post_redirect_params)
  end
end
