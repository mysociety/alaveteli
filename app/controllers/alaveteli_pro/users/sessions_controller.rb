# -*- encoding : utf-8 -*-
# Does not inherit from AlaveteliPro::BaseController as is pre-login
class AlaveteliPro::Users::SessionsController < ApplicationController
  before_filter :check_pro_pricing_enabled

  def new
  end

  private

  def check_pro_pricing_enabled
    raise ActiveRecord::RecordNotFound unless feature_enabled?(:pro_pricing)
  end
end
