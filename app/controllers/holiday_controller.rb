# app/controllers/holiday_controller.rb:
# Calculate dates
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: holiday_controller.rb,v 1.2 2009-10-26 17:52:39 francis Exp $

class HolidayController < ApplicationController

    # This will be tidied up into a proper calendar display etc. For now
    # we have a very basic page that allows us to see what a due date will
    # be given a start date. This isn't exposed anywhere yet.
    def due_date
        if params[:holiday]
            @request_date = Date.strptime(params[:holiday]) or raise "Invalid date"
            @due_date = Holiday.due_date_from(@request_date, 20)
            @skipped = Holiday.all(
                :conditions => [ 'day >= ? AND day <= ?',
                    @request_date.strftime("%F"), @due_date.strftime("%F")
                ]
            ).collect { |h| h.day }.sort
        end
    end

end
