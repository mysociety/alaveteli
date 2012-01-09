# == Schema Information
# Schema version: 108
#
# Table name: holidays
#
#  id          :integer         not null, primary key
#  day         :date
#  description :text
#

# models/holiday.rb:
#
# Store details on, and perform calculations with, public holidays on which 
# the clock for answering FOI requests does not run:
#
#   ... "working day" means any day other than a Saturday, a Sunday, Christmas
#   Day, Good Friday or a day which is a bank holiday under the [1971 c. 80.]
#   Banking and Financial Dealings Act 1971 in any part of the United Kingdom.
#    -- Freedom of Information Act 2000 section 10
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: holiday.rb,v 1.10 2009-10-26 17:52:39 francis Exp $

class Holiday < ActiveRecord::Base

    # Calculate the date on which a request made on a given date falls due.
    # i.e. it is due by the end of that day.
    def Holiday.due_date_from(start_date, working_days)
        # convert date/times into dates
        start_date = start_date.to_date

        # TODO only fetch holidays after the start_date
        holidays = self.all.collect { |h| h.day }.to_set

        # Count forward (20) working days. We start with today as "day zero". The
        # first of the twenty full working days is the next day. We return the
        # date of the last of the twenty.
        
        # This response for example of a public authority complains that we had
        # it wrong.  We didn't (even thought I changed the code for a while,
        # it's changed back now). A day is a day, our lawyer tells us.
        # http://www.whatdotheyknow.com/request/policy_regarding_body_scans#incoming-1100

        days_passed = 0
        response_required_by = start_date

        # Now step forward into each of the 20 days.
        while days_passed < working_days
            response_required_by += 1.day
            next if response_required_by.wday == 0 || response_required_by.wday == 6 # weekend
            next if holidays.include?(response_required_by)
            days_passed += 1
        end

        return response_required_by
    end

end
