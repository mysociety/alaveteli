require 'spec_helper'

describe Announcement do
  describe 'scopes' do
    let!(:admin) { FactoryGirl.create(:admin_user) }
    let!(:user) { FactoryGirl.create(:user) }
    let!(:announcements) do
      {
        generic: FactoryGirl.create(:announcement),
        admin: FactoryGirl.create(:announcement, visibility: 'admin'),
        user: FactoryGirl.create(:announcement, dismissed_by: admin),
        nobody: FactoryGirl.create(:announcement, dismissed_by: [admin, user])
      }
    end

    def announcements_for(*keys)
      announcements.values_at(*keys)
    end

    describe '.for_user' do
      it 'returns undismissed announcements' do
        expect(Announcement.for_user(admin)).
          to match_array(announcements_for(:generic, :admin))
        expect(Announcement.for_user(user)).
          to match_array(announcements_for(:generic, :user))
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

    it 'requires visibility' do
      announcement = FactoryGirl.build(:announcement, visibility: nil)
      expect(announcement).not_to be_valid
    end

    it 'requires visibility ' do
      announcement = FactoryGirl.build(:announcement, visibility: 'foobar')
      expect(announcement).not_to be_valid
    end
  end
end
