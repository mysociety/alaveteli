# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "when updating relations that use counter_cache" do
  # this test case
  #   - passes with Rails 4.0.0
  #   - fails with Rails 3.2.13
  context "appending a record" do

    it "adds 1 to the custom counter_cache value" do
      user = FactoryGirl.create(:user)
      request = FactoryGirl.create(:info_request)

      user.info_requests << request
      user.reload

      expect(user.info_requests.count).to eq(1)
      expect(user.info_requests_count).to eq(1)
    end

  end

  context "updating counter via assignment" do

    # this test case passes with Rails 4.0.0
    it "adds 1 to the custom counter_cache value" do
      user = FactoryGirl.create(:user)
      request = FactoryGirl.build(:info_request)

      request.user = user
      request.save
      user.reload

      expect(user.info_requests.count).to eq(1)
      expect(user.info_requests_count).to eq(1)
    end

    # this fails without the counter_cache patch
    it "correctly handles reassigning a record to a new parent" do
      user1 = FactoryGirl.create(:user)
      user2 = FactoryGirl.create(:user)
      request = FactoryGirl.create(:info_request, :user => user1)

      user1.reload
      expect(user1.info_requests_count).to eq(1)
      expect(user2.info_requests_count).to eq(0)

      request.user = user2
      request.save

      user1.reload
      user2.reload

      expect(user1.info_requests_count).to eq(0)
      expect(user2.info_requests_count).to eq(1)
    end

  end

end
