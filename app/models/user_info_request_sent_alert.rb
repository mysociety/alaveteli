# == Schema Information
# Schema version: 60
#
# Table name: user_info_request_sent_alerts
#
#  id                    :integer         not null, primary key
#  user_id               :integer         not null
#  info_request_id       :integer         not null
#  alert_type            :string(255)     not null
#  info_request_event_id :integer         
#

# models/user_info_request_sent_alert.rb:
# Whether an alert has been sent to this user for this info_request, for a
# given type of alert.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user_info_request_sent_alert.rb,v 1.19 2008-07-17 10:32:01 francis Exp $

class UserInfoRequestSentAlert < ActiveRecord::Base
    belongs_to :user
    belongs_to :info_request

    validates_inclusion_of :alert_type, :in => [ 
        'overdue_1', # tell user that info request has become overdue
        'new_response_reminder_1', # reminder user to classify the recent response
        'new_response_reminder_2', # repeat reminder user to classify the recent response
        'not_clarified_1', # reminder that user has to explain part of the request
    ]
end


