# -*- encoding : utf-8 -*-
# Does not inherit from AlaveteliPro::BaseController as is pre-login
class AlaveteliPro::PlansController < ApplicationController
  before_filter :authenticate, :check_existing_subscription, only: [:show]

  def index
  end

  def show
    stripe_plan = Stripe::Plan.retrieve(params[:id])
    @plan = AlaveteliPro::WithTax.new(stripe_plan)
  rescue Stripe::InvalidRequestError
    raise ActiveRecord::RecordNotFound
  end

  private

  def authenticate
    post_redirect_params = {
      :web => _('To upgrade your account'),
      :email => _('To upgrade your account'),
      :email_subject => _('To upgrade your account') }

    authenticated?(post_redirect_params)
  end

  def check_existing_subscription
    # TODO: This doesn't take the plan in to account
    if @user.pro_account.try(:active?)
      flash[:error] = _('You are already subscribed to this plan')
      redirect_to profile_subscription_path
    end
  end
end
