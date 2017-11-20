# -*- encoding : utf-8 -*-
class Users::AccountsController < ApplicationController
  before_filter :check_pro_pricing_enabled

  def show
  end

  def edit
  end

  def update
    redirect_to users_account_path
  end

  private

  def check_pro_pricing_enabled
    raise ActiveRecord::RecordNotFound unless feature_enabled?(:pro_pricing)
  end
end
