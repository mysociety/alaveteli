# app/controllers/holiday_controller.rb:
# Calculate dates 
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: holiday_controller.rb,v 1.1 2009-03-16 15:55:03 tony Exp $

class HolidayController < ApplicationController

    # This will be tidied up into a proper calendar display etc. For now
    # we have a very basic page that allows us to see what a due date will
    # be given a start date. This isn't exposed anywhere yet.
    def due_date
        if params[:holiday]
            @request_date = Date.strptime(params[:holiday]) or raise "Invalid date"
            @due_date = Holiday.due_date_from(@request_date)
            @skipped = Holiday.all(
                :conditions => [ 'day >= ? AND day <= ?', 
                    @request_date.strftime("%F"), @due_date.strftime("%F")
                ]
            ).collect { |h| h.day }.sort
        end
    end

end
