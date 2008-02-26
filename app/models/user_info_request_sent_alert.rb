# == Schema Information
# Schema version: 36
#
# Table name: user_info_request_sent_alerts
#
#  id              :integer         not null, primary key
#  user_id         :integer         not null
#  info_request_id :integer         not null
#  alert_type      :string(255)     not null
#

# models/user_info_request_sent_alert.rb:
# Whether an alert has been sent to this user for this info_request, for a
# given type of alert.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user_info_request_sent_alert.rb,v 1.2 2008-02-26 15:13:51 francis Exp $

class UserInfoRequestSentAlert < ActiveRecord::Base
    belongs_to :user
    belongs_to :info_request

    validates_inclusion_of :alert_type, :in => [ 
        'overdue_1' # tell user that info request has become overdue
    ]
end


