# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: user_info_request_sent_alerts
#
#  id                    :integer          not null, primary key
#  user_id               :integer          not null
#  info_request_id       :integer          not null
#  alert_type            :string(255)      not null
#  info_request_event_id :integer
#

# models/user_info_request_sent_alert.rb:
# Whether an alert has been sent to this user for this info_request, for a
# given type of alert.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class UserInfoRequestSentAlert < ActiveRecord::Base
  ALERT_TYPES = [
    'overdue_1', # tell user that info request has become overdue
    'very_overdue_1', # tell user that info request has become very overdue
    'new_response_reminder_1', # reminder user to classify the recent
    # response
    'new_response_reminder_2', # repeat reminder user to classify the
    # recent response
    'new_response_reminder_3', # repeat reminder user to classify the
    # recent response
    'not_clarified_1', # reminder that user has to explain part of the
    # request
    'comment_1' # tell user that info request has a new comment
  ]

  belongs_to :user
  belongs_to :info_request

  validates_inclusion_of :alert_type, :in => ALERT_TYPES
end
