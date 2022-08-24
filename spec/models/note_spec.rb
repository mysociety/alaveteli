# == Schema Information
# Schema version: 20220720085105
#
# Table name: notes
#
#  id           :bigint           not null, primary key
#  notable_type :string
#  notable_id   :bigint
#  notable_tag  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  body         :text
#

require 'spec_helper'

RSpec.describe Note, type: :model do
  let(:note) { FactoryBot.build(:note) }

  describe 'validations' do
    specify { expect(note).to be_valid }

    it 'requires body' do
      note.body = nil
      expect(note).not_to be_valid
    end

    it 'requires notable or notable_tag' do
      note.notable = nil
      note.notable_tag = nil
      expect(note).not_to be_valid

      note.notable = nil
      note.notable_tag = 'foo'
      expect(note).to be_valid

      note.notable = PublicBody.first
      note.notable_tag = nil
      expect(note).to be_valid
    end
  end

  describe 'translations' do
    before { note.save! }

    it 'adds translated body' do
      expect(note.body_translations).to_not include(es: 'body')
      AlaveteliLocalization.with_locale(:es) { note.body = 'body' }
      expect(note.body_translations).to include(es: 'body')
    end
  end

  describe 'associations' do
    context 'when info request cited' do
      let(:note) { FactoryBot.build(:note, :for_public_body) }

      it 'belongs to a public body via polymorphic notable' do
        expect(note.notable).to be_a PublicBody
      end
    end
  end
end
