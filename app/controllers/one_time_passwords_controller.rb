# -*- encoding : utf-8 -*-
# app/controllers/one_time_passwords_controller.rb:
# View and update User one time passwords
#
# Copyright (c) 2015 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/
class OneTimePasswordsController < ApplicationController
  before_filter :check_two_factor_config, :authenticate

  def show
  end

  private

  def check_two_factor_config
    unless AlaveteliConfiguration.enable_two_factor_auth
      raise ActiveRecord::RecordNotFound.new('Page not enabled')
    end
  end

  def authenticate
    post_redirect_params = {
      :web => _('To view your two factor authentication details'),
      :email => _('To view your two factor authentication details'),
      :email_subject => _('To view your two factor authentication details') }

    authenticated?(post_redirect_params)
  end
end
