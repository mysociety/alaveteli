# -*- encoding : utf-8 -*-
require 'spec_helper'

describe NotificationMailerHelper do
  include NotificationMailerHelper

  describe "#notifications_by_event_type" do
    let(:response_notifications) { FactoryGirl.create_list(:notification, 5) }
    let(:comment_notification) do
      event = FactoryGirl.create(:comment_event)
      FactoryGirl.create(:notification, info_request_event: event)
    end
    let(:notifications) do
      notifications = []
      notifications.concat(response_notifications)
      notifications << comment_notification
    end

    it "returns a hash of notifications grouped by event type" do
      expected = {
        "response" => response_notifications,
        "comment" => [comment_notification]
      }
      expect(notifications_by_event_type(notifications)).to eq(expected)
    end

    it "returns an empty hash when passed an empty array" do
      expect(notifications_by_event_type([])).to eq({})
    end
  end
end
