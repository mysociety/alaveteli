# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserStats do

  describe ".list_user_domains" do

    context "in general" do

      before do
        FactoryGirl.create(:user, :email => "test@example.com")
      end

      let(:user_stats) { UserStats.list_user_domains }

      it "returns an Array" do
        expect(user_stats).to be_a(Array)
      end

      it "returns the expected results" do
        expected = [
          { "domain" => "localhost", "count"=> "5" },
          { "domain" => "example.com", "count" => "1" }
        ]
        expect(user_stats).to eq(expected)
      end

    end

    context "when passed a start date" do

      before do
        Delorean.time_travel_to "1 week ago"
        FactoryGirl.create(:user, :email => "test@example.com")
        Delorean.back_to_the_present
      end

      it "only returns data for signups created since the start date" do
        expected = [
          { "domain" => "example.com", "count" => "1" }
        ]
        expect(UserStats.list_user_domains(:start_date => 2.weeks.ago)).
          to eq(expected)
      end

    end

    context "when passed a limit" do

      before do
        FactoryGirl.create(:user, :email => "test@example.com")
        FactoryGirl.create(:user, :email => "test@yandex.com")
        FactoryGirl.create(:user, :email => "test@mail.ru")
        FactoryGirl.create(:user, :email => "test@hotmail.com")
      end

      it "limits the length of the results" do
        expect(UserStats.list_user_domains.count).to eq(5)
        expect(UserStats.list_user_domains(:limit => 4).count).to eq(4)
      end

    end

  end

  describe ".count_dormant_users" do

    it "returns the dormant user count for the domain" do
      expect(UserStats.count_dormant_users("localhost")).to eq(2)
    end

    context "when passed a start date" do

      before do
        Delorean.time_travel_to "2 days ago"
        FactoryGirl.create(:user, :email => "newbie@localhost")
        Delorean.back_to_the_present
      end

      it "only returns data for signups created since the start date" do
        last_week = Time.zone.now - 1.week
        expect(UserStats.count_dormant_users("localhost", last_week)).to eq(1)
      end

    end

  end

end
