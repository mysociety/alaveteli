# == Schema Information
# Schema version: 62
#
# Table name: track_things_sent_emails
#
#  id                    :integer         not null, primary key
#  track_thing_id        :integer         not null
#  info_request_event_id :integer         
#  user_id               :integer         
#  public_body_id        :integer         
#  created_at            :datetime        
#  updated_at            :datetime        
#

# models/track_things_sent_email.rb:
# Record that alert has arrived.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: track_things_sent_email.rb,v 1.10 2008-08-09 15:19:01 francis Exp $

class TrackThingsSentEmail < ActiveRecord::Base
    belongs_to :info_request_event
    belongs_to :user
    belongs_to :public_body
    belongs_to :track_thing
end


