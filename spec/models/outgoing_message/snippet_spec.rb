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
    before { snippet.save }

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
end
