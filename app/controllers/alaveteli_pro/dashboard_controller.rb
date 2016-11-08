# -*- encoding : utf-8 -*-
# app/controllers/alaveteli_pro/dashboard_controller.rb
# Dashboard controller, for pro user dashboards.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::DashboardController < AlaveteliPro::BaseController
  def index
    @user = current_user
  end
end
