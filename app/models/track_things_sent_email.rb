# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: track_things_sent_emails
#
#  id                    :integer          not null, primary key
#  track_thing_id        :integer          not null
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
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class TrackThingsSentEmail < ApplicationRecord
  belongs_to :info_request_event,
             inverse_of: :track_things_sent_emails
  belongs_to :user,
             inverse_of: :track_things_sent_emails
  belongs_to :public_body,
             inverse_of: :track_things_sent_emails
  belongs_to :track_thing,
             inverse_of: :track_things_sent_emails

  # Called from cron job delete-old-things
  def self.delete_old_track_things_sent_email
    TrackThingsSentEmail.
      where("updated_at < (now() - interval '1 month')").delete_all
  end
end
