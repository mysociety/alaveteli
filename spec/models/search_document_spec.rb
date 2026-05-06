require 'spec_helper'
# == Schema Information
#
# Table name: search_documents
#
#  sd_id               :bigint           not null, primary key
#  searchable_doc_type :string           not null, primary key
#  searchable_doc_id   :bigint
#  raw_content         :text
#  raw_admin_content   :text
#  section_ref         :text
#  language            :text
#  content_tsv         :tsvector
#  admin_content_tsv   :tsvector
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require 'spec_helper'

RSpec.describe SearchDocument do
  context 'Model Search' do
    it 'search on a model returns a chainable ActiveRecord::Relation' do
      body = FactoryBot.create(:public_body)
      body.reindex
      r = PublicBody.newsearch(body.name, language: 'english')
      expect(r.count).to eq(1)
    end
  end

  context 'when indexing a PublicBody with translations' do
    it 'has one SearchDocument per translation' do
      body = FactoryBot.create(:public_body)
      body.translations.create(locale: 'fr',
                               name: 'Une administration')
      expect(body.translations.size).to eq(2)
      expect(body.name(:fr)).to eq('Une administration')

      body.reindex
      expect(SearchDocument.count).to eq(2)
    end
  end
end
