# -*- encoding : utf-8 -*-
# app/controllers/alaveteli_pro/base_controller.rb
# Base controller for other controllers in the alaveteli_pro module.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::BaseController < ApplicationController
  before_filter :pro_user_authenticated?

  # A pro-specific version of user_authenticated? that pro controller actions
  # can use to check for (or force a login for) an authenticated pro user
  def pro_user_authenticated?(reason_params = nil)
    if reason_params.nil?
      reason_params = {
        web: _("To access Alaveteli Professional"),
        email: _("Then you can access Alaveteli Professional")
      }
    end
    if authenticated?(reason_params)
      unless current_user.pro?
        redirect_to(
          frontpage_path,
          flash: {
            notice: _("This page is only accessible to Alaveteli " \
                      "Professional users")
          }
        )
      end
      return true
    end
    return false
  end
end
