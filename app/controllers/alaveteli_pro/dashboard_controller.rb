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
    @phase_counts = @user.request_summaries.
                      joins(:request_summary_categories).
                      references(:request_summary_categories).
                      group("request_summary_categories.slug").
                      count("request_summary_categories.id")
    @phase_counts['total'] = @phase_counts.values.reduce(0, :+)
    @phase_counts['not_drafts'] =
      @phase_counts['total'] - @phase_counts['draft'].to_i
  end
end
