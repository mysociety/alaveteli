# == Schema Information
# Schema version: 20220322100510
#
# Table name: track_things_sent_emails
#
#  id                    :bigint           not null, primary key
#  track_thing_id        :bigint           not null
#  info_request_event_id :bigint
#  user_id               :bigint
#  public_body_id        :bigint
#  created_at            :datetime
#  updated_at            :datetime
#

require 'spec_helper'

RSpec.describe TrackThingsSentEmail, "when tracking things sent email" do
end
