# == Schema Information
#
# Table name: announcements
#
#  id         :integer          not null, primary key
#  visibility :string
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  title      :string
#  style      :string           default("default"), not null
#

require 'spec_helper'

RSpec.describe Announcement do
  describe 'scopes' do
    let!(:admin) { FactoryBot.create(:admin_user) }
    let!(:user) { FactoryBot.create(:user) }

    let!(:site_wide_announcement_1) do
      FactoryBot.create(:announcement, dismissed_by: admin,
                                       created_at: Date.yesterday)
    end
    let!(:site_wide_announcement_2) do
      FactoryBot.create(:announcement, dismissed_by: user)
    end
    let!(:admin_announcement) do
      FactoryBot.create(:announcement, visibility: 'admin')
    end
    let!(:past_admin_announcement) do
      FactoryBot.create(:announcement, visibility: 'admin',
                                       created_at: Date.yesterday)
    end
    let!(:dismissed_admin_announcement) do
      FactoryBot.create(:announcement, visibility: 'admin',
                                       dismissed_by: admin)
    end

    describe '.visible_to' do
      it 'returns announcements visible for the role' do
        expect(Announcement.visible_to('everyone')).
          to match_array([site_wide_announcement_1, site_wide_announcement_2])
        expect(Announcement.visible_to('admin')).
          to match_array([admin_announcement,
                          past_admin_announcement,
                          dismissed_admin_announcement])
      end
    end

    describe '.for_user_with_roles' do
      it 'returns undismissed announcements made after the user signed up which match visibility with the user roles' do
        expect(Announcement.for_user_with_roles(admin, 'admin')).
          to match_array([admin_announcement])
        expect(Announcement.for_user_with_roles(user, 'admin')).
          to be_empty
      end
    end

    describe '.site_wide_for_user' do
      it 'without arguments, return all site wide announcements' do
        expect(Announcement.site_wide_for_user).
          to match_array([site_wide_announcement_1, site_wide_announcement_2])
      end

      it 'returns site wide announcements made after the most recent dismissed announcement' do
        expect(Announcement.site_wide_for_user(admin)).
          to match_array([site_wide_announcement_2])
        expect(Announcement.site_wide_for_user(user)).
          to be_empty
      end

      it 'without an user, return any announcements made after the given announcement' do
        expect(Announcement.site_wide_for_user(nil, site_wide_announcement_1)).
          to match_array([site_wide_announcement_2])
        expect(Announcement.site_wide_for_user(nil, site_wide_announcement_2)).
          to be_empty
      end
    end
  end

  describe '#rich_body' do
    let(:announcement) do
      FactoryBot.create(:announcement, rich_body: 'English body')
    end

    it 'falls back to the default locale when there is no translation' do
      AlaveteliLocalization.with_locale(:es) do
        expect(announcement.rich_body.to_plain_text).to eq('English body')
      end
    end

    it 'prefers the body in the current locale' do
      AlaveteliLocalization.with_locale(:es) do
        announcement.rich_body = 'Cuerpo'
        announcement.save!
        expect(announcement.rich_body.to_plain_text).to eq('Cuerpo')
      end

      expect(announcement.rich_body.to_plain_text).to eq('English body')
    end
  end

  describe 'vaidations' do
    it 'has valid factory' do
      announcement = FactoryBot.build(:announcement)
      expect(announcement).to be_valid
    end

    it 'requires rich_body' do
      announcement = FactoryBot.build(:announcement, rich_body: nil)
      expect(announcement).not_to be_valid
    end

    it 'defaults to the default style' do
      expect(Announcement.new).to be_default_style
    end

    it 'allows the colour styles' do
      %w[red yellow green blue].each do |style|
        expect(FactoryBot.build(:announcement, style: style)).to be_valid
      end
    end

    it 'rejects unknown styles' do
      expect { FactoryBot.build(:announcement, style: 'orange') }.
        to raise_error(ArgumentError)
    end

    it 'requires user' do
      announcement = FactoryBot.build(:announcement, user: nil)
      expect(announcement).not_to be_valid
    end

    it 'requires visibility' do
      announcement = FactoryBot.build(:announcement, visibility: nil)
      expect(announcement).not_to be_valid
    end

    it 'requires visibility ' do
      announcement = FactoryBot.build(:announcement, visibility: 'foobar')
      expect(announcement).not_to be_valid
    end
  end
end
