require 'spec_helper'
# == Schema Information
#
# Table name: search_documents
#
#  sd_id             :bigint           not null, primary key
#  searchable_type   :string           not null, primary key
#  searchable_id     :bigint
#  raw_content       :text
#  raw_admin_content :text
#  section_ref       :text
#  language          :text
#  content_tsv       :tsvector
#  admin_content_tsv :tsvector
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
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
      n = FactoryBot.create(:note, rich_body: 'My note in English')
      n.translations.create(locale: 'fr',
                            rich_body: 'Une note en Français')
      expect(n.translations.size).to eq(2)

      n.reindex
      expect(SearchDocument.count).to eq(2)

      search1 = Note.newsearch("Français", admin_mode: true,
                                           language: 'english')
      expect(search1).to match_array([])

      search2 = Note.newsearch("Français", admin_mode: true, language: "french")
      expect(search2).to match_array([n])

      search3 = Note.newsearch("english", admin_mode: true, language: "french")
      expect(search3).to match_array([n])
    end
  end

  context 'handles known problematic searches from various sites' do
    # from https://github.com/mysociety/alaveteli/issues/1179
    it 'finds UK public bodies' do
      with_default_locale(:en) do
        nhs = FactoryBot.create(:public_body, name: "NHS England")
        bodies = [
          nhs,
          FactoryBot.create(:public_body, name: "NHS Improving Quality"),
          FactoryBot.create(:public_body, name: "NHSX"),
          FactoryBot.create(
            :public_body,
            name: "Northern England NHS fictitious center"
          )
        ]
        bodies.each(&:reindex)
        expect(PublicBody.newsearch("NHS England").first).to eq(nhs)
      end
    end

    it 'finds French public bodies' do
      with_default_locale(:fr_FR) do
        AlaveteliLocalization.with_locale(:fr_FR) do
          body = FactoryBot.create(
            :public_body,
            name: "Ministère de l'Intérieur"
          )
          body.reindex
          expect(PublicBody.newsearch(
                   "ministere intérieur",
            language: 'french'
                 )).to match_array([body])
          expect(
            PublicBody.newsearch("ministere interieur")
          ).to match_array([body])
          expect(
            PublicBody.newsearch("ministere de l'intérieur")
          ).to match_array([body])
        end
      end
    end

    it 'finds the Australian attorney general' do
      # from https://github.com/mysociety/alaveteli/issues/1179#issuecomment-304157132
      with_default_locale(:en) do
        ag = FactoryBot.create(:public_body,
name: "WA Department of the Attorney General")
        ag.reindex
        expect(PublicBody.newsearch("WA Attorney General")).to match_array([ag])
        expect(PublicBody.newsearch("Attorney General")).to match_array([ag])
      end
    end

    it 'finds the Swedish name of a public body in either locale' do
      with_default_locale(:sv) do
        st = FactoryBot.create(:public_body, name: "Skånetrafiken")
        st.translations.create(locale: "sv",
                               name: "Skånetrafiken")
        st.reindex
        s = SearchDocument.first
        AlaveteliLocalization.with_locale(:sv) do
          expect(PublicBody.newsearch(
                   "Skånetrafiken",
               language: 'swedish'
                 )).to match_array([st])
        end
        AlaveteliLocalization.with_locale(:en) do
          expect(PublicBody.newsearch(
                   "Skånetrafiken",
               language: 'english'
                 )).to match_array([st])
        end
      end
    end
  end
end
