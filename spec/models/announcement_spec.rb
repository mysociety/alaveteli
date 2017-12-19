require 'spec_helper'

describe Announcement do
  describe 'scopes' do
    let!(:user1) { FactoryGirl.create(:user) }
    let!(:user2) { FactoryGirl.create(:user) }
    let!(:announcements) do
      {
        generic: FactoryGirl.create(:announcement),
        user1: FactoryGirl.create(:announcement, dismissed_by: user2),
        nobody: FactoryGirl.create(:announcement, dismissed_by: [user1, user2])
      }
    end

    def announcements_for(*keys)
      announcements.values_at(*keys)
    end

    describe '.for_user' do
      it 'returns undismissed announcements' do
        expect(Announcement.for_user(user1)).
          to match_array(announcements_for(:generic, :user1))
        expect(Announcement.for_user(user2)).
          to match_array(announcements_for(:generic))
      end
    end
  end

  describe 'vaidations' do
    it 'has valid factory' do
      announcement = FactoryGirl.build(:announcement)
      expect(announcement).to be_valid
    end

    it 'requires content' do
      announcement = FactoryGirl.build(:announcement, content: nil)
      expect(announcement).not_to be_valid
    end

    it 'requires user' do
      announcement = FactoryGirl.build(:announcement, user: nil)
      expect(announcement).not_to be_valid
    end
  end
end
