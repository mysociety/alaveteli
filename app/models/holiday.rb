# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: holidays
#
#  id          :integer          not null, primary key
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
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class Holiday < ActiveRecord::Base

    validates_presence_of :day

    def self.holidays
        @@holidays ||= all.collect { |h| h.day }.to_set
    end

    def self.weekend_or_holiday?(date)
        date.wday == 0 || date.wday == 6 || Holiday.holidays.include?(date)
    end

    def self.due_date_from(start_date, days, type_of_days)
        case type_of_days
        when "working"
            Holiday.due_date_from_working_days(start_date, days)
        when "calendar"
            Holiday.due_date_from_calendar_days(start_date, days)
        else
            raise "Unexpected value for type_of_days: #{type_of_days}"
        end
    end

    # Calculate the date on which a request made on a given date falls due when
    # days are given in working days
    # i.e. it is due by the end of that day.
    def self.due_date_from_working_days(start_date, working_days)
        # convert date/times into dates
        start_date = start_date.to_date

        # Count forward the number of working days. We start with today as "day
        # zero". The first of the full working days is the next day. We return
        # the date of the last of the number of working days.
        #
        # This response for example of a public authority complains that we had
        # it wrong.  We didn't (even thought I changed the code for a while,
        # it's changed back now). A day is a day, our lawyer tells us.
        # http://www.whatdotheyknow.com/request/policy_regarding_body_scans#incoming-1100

        days_passed = 0
        response_required_by = start_date

        # Now step forward into each of the working days.
        while days_passed < working_days
            response_required_by += 1
            days_passed += 1 unless weekend_or_holiday?(response_required_by)
        end

        response_required_by
    end

    # Calculate the date on which a request made on a given date falls due when
    # the days are given in calendar days (rather than working days)
    # If the due date falls on a weekend or a holiday then the due date is the
    # next weekday that isn't a holiday.
    def self.due_date_from_calendar_days(start_date, days)
        # convert date/times into dates
        start_date = start_date.to_date

        response_required_by = start_date + days
        while weekend_or_holiday?(response_required_by)
            response_required_by += 1
        end
        response_required_by
    end
end
