# -*- encoding : utf-8 -*-
# Does not inherit from AlaveteliPro::BaseController as is pre-login
class AlaveteliPro::UsersController < ApplicationController
  before_filter :check_pro_pricing_enabled

  def create
    # Create a User
    # Create an associated ProAccount
    # Give them a :pro Role
    # Render the "Go check your email" confirmation page
    render :confirm
  end

  private

  def check_pro_pricing_enabled
    raise ActiveRecord::RecordNotFound unless feature_enabled?(:pro_pricing)
  end
end
