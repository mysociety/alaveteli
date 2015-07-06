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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TrackThingsSentEmail, "when tracking things sent email" do
end
