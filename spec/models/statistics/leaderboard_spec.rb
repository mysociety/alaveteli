require 'spec_helper'

RSpec.describe Statistics::Leaderboard do
  let(:statistics) { described_class.new }

  describe '#all_time_requesters' do
    it 'gets most frequent requesters' do
      User.destroy_all

      user1 = FactoryBot.create(:user)
      user2 = FactoryBot.create(:user)
      user3 = FactoryBot.create(:user)

      travel_to(6.months.ago) do
        5.times { FactoryBot.create(:info_request, user: user1) }
        2.times { FactoryBot.create(:info_request, user: user2) }
        FactoryBot.create(:info_request, user: user3)
      end

      expect(statistics.all_time_requesters).
        to eq({ user1 => 5,
                user2 => 2,
                user3 => 1 })
    end
  end

  describe '#last_28_day_requesters' do
    it 'gets recent frequent requesters' do
      user_with_3_requests = FactoryBot.create(:user)
      3.times { FactoryBot.create(:info_request, user: user_with_3_requests) }
      user_with_2_requests = FactoryBot.create(:user)
      2.times { FactoryBot.create(:info_request, user: user_with_2_requests) }
      user_with_1_request = FactoryBot.create(:user)
      FactoryBot.create(:info_request, user: user_with_1_request)
      user_with_an_old_request = FactoryBot.create(:user)
      FactoryBot.create(:info_request,
                        user: user_with_an_old_request,
                        created_at: 2.months.ago)

      expect(statistics.last_28_day_requesters).
        to eql({ user_with_3_requests => 3,
                 user_with_2_requests => 2,
                 user_with_1_request => 1 })
    end
  end

  describe '#all_time_commenters' do
    let(:many_comments) { FactoryBot.create(:user) }
    let(:some_comments) { FactoryBot.create(:user) }
    let!(:none_comments) { FactoryBot.create(:user) }

    before do
      FactoryBot.create(:comment, user: many_comments)
      FactoryBot.create(:comment, user: many_comments)
      FactoryBot.create(:comment, user: some_comments)
      FactoryBot.create(:comment, user: many_comments)
      FactoryBot.create(:comment, user: some_comments)
      FactoryBot.create(:comment, user: many_comments)
    end

    it 'gets most frequent commenters' do
      # FIXME: This uses fixtures. Change it to use factories when we can.
      expect(statistics.all_time_commenters).
        to eql({ many_comments => 4,
                 some_comments => 2,
                 users(:silly_name_user) => 1 })
    end
  end

  describe '#last_28_day_commenters' do
    it 'gets recent frequent commenters' do
      user_with_3_comments = FactoryBot.create(:user)
      3.times { FactoryBot.create(:comment, user: user_with_3_comments) }
      user_with_2_comments = FactoryBot.create(:user)
      2.times { FactoryBot.create(:comment, user: user_with_2_comments) }
      user_with_1_comment = FactoryBot.create(:user)
      FactoryBot.create(:comment, user: user_with_1_comment)
      user_with_an_old_comment = FactoryBot.create(:user)
      FactoryBot.create(:comment,
                        user: user_with_an_old_comment,
                        created_at: 2.months.ago)

      expect(statistics.last_28_day_commenters).
        to eql({ user_with_3_comments => 3,
                 user_with_2_comments => 2,
                 user_with_1_comment => 1 })
    end
  end
end
