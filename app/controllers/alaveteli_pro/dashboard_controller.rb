# -*- encoding : utf-8 -*-
# app/controllers/alaveteli_pro/dashboard_controller.rb
# Dashboard controller, for pro user dashboards.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::DashboardController < AlaveteliPro::BaseController
  def index
    @user = current_user
    @to_do_list = AlaveteliPro::ToDoList::List.new(@user)
    @page = (params[:page] || "1").to_i
    @page = 1 if @page < 1
    @per_page = 10
    @activity_list = AlaveteliPro::ActivityList::List.new(@user, @page, @per_page)
    @announcements = Announcement.
      for_user_with_roles(current_user, :pro).
      limit(3)
  end
end
