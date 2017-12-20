require 'spec_helper'

describe Announcement do
  describe 'scopes' do
    let!(:admin) { FactoryGirl.create(:admin_user) }
    let!(:user) { FactoryGirl.create(:user) }
    let!(:announcements) do
      {
        generic: FactoryGirl.create(:announcement),
        past: FactoryGirl.create(:announcement, created_at: Date.yesterday),
        admin: FactoryGirl.create(:announcement, visibility: 'admin'),
        user: FactoryGirl.create(:announcement, dismissed_by: admin),
        nobody: FactoryGirl.create(:announcement, dismissed_by: [admin, user])
      }
    end

    def announcements_for(*keys)
      announcements.values_at(*keys)
    end

    describe '.site_wide' do
      it 'returns announcements visible to everybody' do
        expect(Announcement.site_wide).
          to match_array(announcements_for(:generic, :past, :user, :nobody))
      end
    end

    describe '.visible_to' do
      it 'returns announcements visible for the role' do
        expect(Announcement.visible_to('everyone')).
          to match_array(announcements_for(:generic, :past, :user, :nobody))
        expect(Announcement.visible_to('admin')).
          to match_array(announcements_for(:admin))
      end
    end

    describe '.for_user' do
      it 'returns undismissed announcements' do
        expect(Announcement.for_user(admin)).
          to match_array(announcements_for(:generic, :past, :admin))
        expect(Announcement.for_user(user)).
          to match_array(announcements_for(:generic, :past, :user))
      end
    end

    describe '.for_user_with_roles' do
      it 'returns undismissed announcements, with correct role visibility and not in the past' do
        expect(Announcement.for_user_with_roles(admin, 'admin')).
          to match_array(announcements_for(:admin))
        expect(Announcement.for_user_with_roles(user, 'admin')).
          to be_empty
        expect(Announcement.for_user_with_roles(admin, 'everyone')).
          to match_array(announcements_for(:generic))
        expect(Announcement.for_user_with_roles(user, 'everyone')).
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
