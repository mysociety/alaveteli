# == Schema Information
# Schema version: 74
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
# $Id: holiday.rb,v 1.4 2009-03-16 21:06:07 francis Exp $

class Holiday < ActiveRecord::Base

    # Calculate the date on which a request made on a given date falls due.
    def Holiday.due_date_from(start_date)
        # convert date/times into dates
        start_date = start_date.to_date

        # TODO only fetch holidays after the start_date
        holidays = self.all.collect { |h| h.day }.to_set

        # Count forward 20 working days. We start with today (or if not a working day,
        # the next working day*) as "day zero". The first of the twenty full
        # working days is the next day. We return the date of the last of the twenty.
        #
        # * See this response for example of a public authority complaining when we got
        # that detail wrong: http://www.whatdotheyknow.com/request/policy_regarding_body_scans#incoming-1100

        # We have to skip non-working days at start to find day zero, so start at
        # day -1 and at yesterday, so we can do that.
        days_passed = -1 
        response_required_by = start_date - 1.day

        # Now step forward into day zero, and then each of the 20 days.
        while days_passed < 20
            response_required_by += 1.day
            next if response_required_by.wday == 0 || response_required_by.wday == 6 # weekend
            next if holidays.include?(response_required_by)
            days_passed += 1
        end

        return response_required_by
    end

end
