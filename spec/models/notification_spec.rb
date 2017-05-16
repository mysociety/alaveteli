# -*- encoding : utf-8 -*-
require "spec_helper"

RSpec.describe Notification do
  it "requires an info_request_event" do
    notification = FactoryGirl.build(:notification,
                                     info_request_event: nil,
                                     user: FactoryGirl.create(:user))
    expect(notification).not_to be_valid
  end

  it "requires a user" do
    notification = FactoryGirl.build(:notification, user: nil)
    expect(notification).not_to be_valid
  end

  it "requires a frequency" do
    notification = FactoryGirl.build(:notification, frequency: nil)
    expect(notification).not_to be_valid
  end

  it "requires a send_after timestamp" do
    notification = FactoryGirl.build(:notification, send_after: nil)
    expect(notification).not_to be_valid
  end
end
