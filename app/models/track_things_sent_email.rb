# == Schema Information
# Schema version: 49
#
# Table name: track_things_sent_emails
#
#  id                    :integer         not null, primary key
#  track_thing_id        :integer         not null
#  info_request_event_id :integer         
#  user_id               :integer         
#  public_body_id        :integer         
#

# models/track_things_sent_email.rb:
# Record that alert has arrived.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: track_things_sent_email.rb,v 1.1 2008-04-01 16:40:37 francis Exp $

class TrackThingsSentEmail < ActiveRecord::Base
    belongs_to :info_request_event
    belongs_to :user
    belongs_to :public_body
end


