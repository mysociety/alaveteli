# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserStats do

  describe ".list_user_domains" do

    context "in general" do

      before do
        User.destroy_all
        FactoryBot.create(:user, :email => "test1@localhost")
        FactoryBot.create(:user, :email => "test2@localhost")
        FactoryBot.create(:user, :email => "test@example.com")
      end

      let(:user_stats) { UserStats.list_user_domains }

      it "returns an Array" do
        expect(user_stats).to be_a(Array)
      end

      it "returns the expected results" do
        expected = [
          { "domain" => "localhost", "count"=> "2" },
          { "domain" => "example.com", "count" => "1" }
        ]
        expect(user_stats).to eq(expected)
      end

    end

    context "when passed a start date" do

      before do
        Delorean.time_travel_to "1 week ago"
        FactoryBot.create(:user, :email => "test@example.com")
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
        FactoryBot.create(:user, :email => "test@example.com")
        FactoryBot.create(:user, :email => "test@yandex.com")
        FactoryBot.create(:user, :email => "test@mail.ru")
        FactoryBot.create(:user, :email => "test@hotmail.com")
      end

      it "limits the length of the results" do
        expect(UserStats.list_user_domains.count).to eq(5)
        expect(UserStats.list_user_domains(:limit => 4).count).to eq(4)
      end

    end

  end

  describe ".count_dormant_users" do
    before do
      Delorean.time_travel_to(2.weeks.ago) do
        requester = FactoryBot.create(:user, :email => "active@example.com")
        commenter = FactoryBot.create(:user, :email => "commenter@example.com")
        tracker = FactoryBot.create(:user, :email => "tracker@example.com")
        dormant = FactoryBot.create(:user, :email => "dormant1@example.com")

        request = FactoryBot.create(:info_request, :user => requester)
        comment = FactoryBot.create(:comment, :body => "hi!",
                                              :user => commenter,
                                              :info_request => request)
        track = FactoryBot.create(:search_track,
                                  :tracking_user => tracker)
      end

      FactoryBot.create(:user, :email => "dormant2@example.com")
    end

    it "returns the dormant user count for the domain" do
      expect(UserStats.count_dormant_users("example.com")).to eq(2)
    end

    context "when passed a start date" do

      it "only returns data for signups created since the start date" do
        expect(UserStats.count_dormant_users("example.com", 1.week.ago)).
          to eq(1)
      end

    end

  end

  describe ".unbanned_by_domain" do
    before do
      Delorean.time_travel_to(1.month.ago) do
        @user1 = FactoryBot.create(:user, :email => "test@example.com")
        @banned = FactoryBot.create(:user,
                                    :email => "banned@example.com",
                                    :ban_text => "Banned")
      end
      @user2 = FactoryBot.create(:user, :email => "newbie@example.com")
      @admin = FactoryBot.create(:admin_user, :email => "admin@example.com")
    end

    it "returns a list of eligible users" do
      expect(UserStats.unbanned_by_domain("example.com")).
        to match_array([@user1, @user2])
    end

    it "does not include banned users" do
      expect(UserStats.unbanned_by_domain("example.com")).to_not include(@banned)
    end

    it "does not include admins" do
      expect(UserStats.unbanned_by_domain("example.com")).to_not include(@admin)
    end

    context "when given a start date" do

      it "only returns data for signups created since the start date" do
        expect(UserStats.unbanned_by_domain("example.com", 1.week.ago)).
          to match_array([@user2])
      end

    end

  end

end
