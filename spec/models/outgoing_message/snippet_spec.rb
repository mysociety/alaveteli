# == Schema Information
# Schema version: 20220210114052
#
# Table name: outgoing_message_snippets
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  name       :string
#  body       :text
#

require 'spec_helper'

RSpec.describe OutgoingMessage::Snippet, type: :model do
  let(:snippet) { FactoryBot.build(:outgoing_message_snippet) }

  describe 'validations' do
    specify { expect(snippet).to be_valid }

    it 'requires name' do
      snippet.name = nil
      expect(snippet).not_to be_valid
    end

    it 'requires body' do
      snippet.body = nil
      expect(snippet).not_to be_valid
    end
  end

  describe 'translations' do
    before { snippet.save! }

    it 'adds translated name' do
      expect(snippet.name_translations).to_not include(es: 'name')
      AlaveteliLocalization.with_locale(:es) { snippet.name = 'name' }
      expect(snippet.name_translations).to include(es: 'name')
    end

    it 'adds translated body' do
      expect(snippet.body_translations).to_not include(es: 'body')
      AlaveteliLocalization.with_locale(:es) { snippet.body = 'body' }
      expect(snippet.body_translations).to include(es: 'body')
    end
  end

  describe 'taggable' do
    let!(:exemption_12_snippet) do
      FactoryBot.create(:outgoing_message_snippet, tag_string: 'exemption:s_12')
    end

    let!(:tagged_snippet) do
      FactoryBot.create(:outgoing_message_snippet, tag_string: 'tagged')
    end

    let!(:other_snippet) do
      FactoryBot.create(:outgoing_message_snippet, tag_string: 'foo bar')
    end

    describe '.with_tag' do
      it 'should return records with key/value tags' do
        snippets = described_class.with_tag('exemption:s_14')
        expect(snippets).to be_empty

        snippets = described_class.with_tag('exemption:s_12')
        expect(snippets).to match_array([exemption_12_snippet])
        expect(snippets).to_not include(other_snippet)
      end

      it 'should return records with tags' do
        snippets = described_class.with_tag('untagged')
        expect(snippets).to be_empty

        snippets = described_class.with_tag('tagged')
        expect(snippets).to match_array([tagged_snippet])
        expect(snippets).to_not include(other_snippet)
      end

      it 'should be chainable to include more than one tag' do
        snippets = described_class.with_tag('foo').with_tag('bar')
        expect(snippets).to_not include(exemption_12_snippet)
        expect(snippets).to_not include(tagged_snippet)
        expect(snippets).to include(other_snippet)
      end
    end

    describe '.without_tag' do
      it 'should not return records with key/value tags' do
        snippets = described_class.without_tag('exemption:s_12')
        expect(snippets).to_not include(exemption_12_snippet)
        expect(snippets).to include(other_snippet)

        snippets = described_class.without_tag('exemption:s_14')
        expect(snippets).to include(exemption_12_snippet)
        expect(snippets).to include(other_snippet)
      end

      it 'should not return records with tags' do
        snippets = described_class.without_tag('tagged')
        expect(snippets).to_not include(tagged_snippet)
        expect(snippets).to include(other_snippet)

        snippets = described_class.without_tag('untagged')
        expect(snippets).to include(tagged_snippet)
        expect(snippets).to include(other_snippet)
      end

      it 'should be chainable to exclude more than one tag' do
        snippets = described_class.without_tag('exemption:s_12').
          without_tag('tagged')
        expect(snippets).to_not include(exemption_12_snippet)
        expect(snippets).to_not include(tagged_snippet)
        expect(snippets).to include(other_snippet)
      end
    end

    it 'show .with_tag and .without_tag are chainable' do
      old_tagged_snippet = FactoryBot.create(
        :outgoing_message_snippet, tag_string: 'tagged old'
      )

      snippets = described_class.with_tag('tagged').without_tag('old')
      expect(snippets).to_not include(old_tagged_snippet)
      expect(snippets).to include(tagged_snippet)
    end

    describe '.tags' do
      subject { described_class.tags }

      it 'returns all tags used for the given model' do
        is_expected.to match_array(['exemption:s_12', 'tagged', 'foo', 'bar'])
      end
    end
  end
end
