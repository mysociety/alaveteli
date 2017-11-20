# -*- encoding : utf-8 -*-
# Does not inherit from AlaveteliPro::BaseController as is pre-login
class AlaveteliPro::PricingController < ApplicationController
  before_filter :check_pro_pricing_enabled

  def index
  end

  private

  def check_pro_pricing_enabled
    raise ActiveRecord::RecordNotFound unless feature_enabled?(:pro_pricing)
  end
end
