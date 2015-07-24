# -*- encoding : utf-8 -*-
# app/controllers/holiday_controller.rb:
# Calculate dates
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class HolidayController < ApplicationController

  # This will be tidied up into a proper calendar display etc. For now
  # we have a very basic page that allows us to see what a due date will
  # be given a start date. This isn't exposed anywhere yet.
  def due_date
    if params[:holiday]
      @request_date = Date.strptime(params[:holiday]) or raise "Invalid date"
      @due_date = Holiday.due_date_from(@request_date, AlaveteliConfiguration::reply_late_after_days, AlaveteliConfiguration::working_or_calendar_days)
      @skipped = Holiday.all(
        :conditions => [ 'day >= ? AND day <= ?',
                         @request_date.strftime("%F"), @due_date.strftime("%F")
                         ]
      ).collect { |h| h.day }.sort
    end
  end

end
