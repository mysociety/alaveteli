# == Schema Information
# Schema version: 108
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
# $Id: track_things_sent_email.rb,v 1.22 2009-09-17 21:10:05 francis Exp $

class TrackThingsSentEmail < ActiveRecord::Base
    belongs_to :info_request_event
    belongs_to :user
    belongs_to :public_body
    belongs_to :track_thing

    # Called from cron job delete-old-things
    def self.delete_old_track_things_sent_email
        TrackThingsSentEmail.delete_all "updated_at < (now() - interval '1 month')"
    end

end


