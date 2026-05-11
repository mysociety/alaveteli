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
  context 'when indexing a model with translations' do
    it 'PublicBody has one SearchDocument per translation' do
      name_en = "Some public authority ABCD"
      name_fr = "Une administration ABCD"
      body = FactoryBot.create(:public_body, name: name_en)
      body.translations.create(locale: 'fr',
                               name: name_fr)
      expect(body.translations.size).to eq(2)
      expect(body.name(:fr)).to eq(name_fr)

      body.reindex

      expect(SearchDocument.count).to eq(2)
      expect(PublicBody.newsearch("ABCD", language: 'french')).to eq([body])
      expect(PublicBody.newsearch(
               "authority",
               language: 'french'
             )).to match_array([])
      expect(PublicBody.newsearch(
               "administration",
               language: 'english'
             )).to match_array([])
    end

    it 'Note has one SearchDocument per translation' do
      n = FactoryBot.create(:note, body: 'A note in English')
      n.translations.create(locale: 'fr',
                            body: 'Une note en Français')
      expect(n.translations.size).to eq(2)
      expect(n.body(:fr)).to eq('Une note en Français')
      expect(n.body(:en)).to eq('A note in English')

      n.reindex
      expect(SearchDocument.count).to eq(2)

      search1 = Note.newsearch("Français", admin_mode: true)
      expect(search1).to match_array([n])

      search2 = Note.newsearch("Français", admin_mode: true, language: "french")
      expect(search2).to match_array([n])

      search3 = Note.newsearch("english", admin_mode: true, language: "french")
      expect(search3).to match_array([n])
    end
  end
end
