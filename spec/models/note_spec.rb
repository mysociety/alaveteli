# == Schema Information
# Schema version: 20240227080436
#
# Table name: notes
#
#  id           :bigint           not null, primary key
#  notable_type :string
#  notable_id   :bigint
#  notable_tag  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  style        :string           default("original"), not null
#  body         :text
#

require 'spec_helper'

RSpec.describe Note, type: :model do
  let(:note) { FactoryBot.build(:note) }

  describe 'validations' do
    specify { expect(note).to be_valid }

    context 'original style' do
      let(:note) { FactoryBot.build(:note, :original) }

      it 'requires body' do
        note.body = nil
        expect(note).not_to be_valid
      end
    end

    it 'requires rich body' do
      note.rich_body = nil
      expect(note).not_to be_valid
    end

    it 'requires style' do
      note.style = nil
      expect(note).not_to be_valid
    end

    it 'requires known style' do
      expect { note.style = 'invalid' }.
        to raise_error(ArgumentError, "'invalid' is not a valid style")
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

    def plain_body
      note.rich_body_translations.transform_values(&:to_plain_text)
    end

    it 'adds translated rich_body' do
      expect(plain_body).to_not include(es: 'content')
      AlaveteliLocalization.with_locale(:es) { note.rich_body = 'content' }
      expect(plain_body).to include(es: 'content')
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

  describe '.sort' do
    let(:original) { FactoryBot.build(:note, :original) }
    let(:red) { FactoryBot.build(:note, style: 'red') }
    let(:green) { FactoryBot.build(:note, style: 'green') }
    let(:blue_1) { FactoryBot.build(:note, style: 'blue') }
    let(:blue_2) { FactoryBot.build(:note, style: 'blue') }
    let(:yellow) { FactoryBot.build(:note, style: 'yellow') }

    subject do
      described_class.sort([yellow, blue_1, green, red, original, blue_2])
    end

    it 'sorts based on enum value index' do
      is_expected.to eq([red, yellow, green, blue_1, blue_2, original])
    end
  end

  describe '#to_plain_text' do
    subject { note.to_plain_text }

    context 'with original style note' do
      let(:note) { FactoryBot.build(:note, :original, body: '<h1>title</h1>') }
      it { is_expected.to eq('title') }
    end

    context 'with styled note' do
      let(:note) { FactoryBot.build(:note, rich_body: '<h1>title</h1>') }
      it { is_expected.to eq('title') }
    end
  end
end
