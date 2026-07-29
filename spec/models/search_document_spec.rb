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
  # created eagerly so the after_commit indexes it before the search runs
  let!(:user) do
    FactoryBot.create(:user, name: 'Florence Nightingale',
                             about_me: 'I enjoy data visualisation')
  end

  context 'model search' do
    it 'returns a chainable ActiveRecord::Relation' do
      results = User.newsearch('Florence', admin_mode: true)
      expect(results).to be_an(ActiveRecord::Relation)
      expect(results.where(email_confirmed: true).count).to eq(1)
    end

    it 'finds users by admin indexed fields' do
      expect(
        User.newsearch(user.email, admin_mode: true)
      ).to match_array([user])
      expect(
        User.newsearch('data visualisation', admin_mode: true)
      ).to match_array([user])
    end

    it 'does not match admin indexed fields without admin_mode' do
      expect(User.newsearch('Florence')).to match_array([])
    end

    it 'raises for models that have not been made searchable' do
      expect { Comment.newsearch('anything') }.
        to raise_error(NotImplementedError)
    end
  end

  context 'bounce text indexing' do
    let!(:bounced) do
      FactoryBot.create(:user).tap do |u|
        u.record_bounce('mail delivery failed: mailbox full')
      end
    end

    it 'finds users by bounce text in admin mode' do
      expect(User.newsearch('mailbox full', admin_mode: true)).to include(bounced)
    end

    it 'does not expose bounce text to non-admin search' do
      expect(User.newsearch('mailbox full')).to match_array([])
    end
  end

  context 'input validation' do
    it 'rejects a model given as a string' do
      expect { SearchDocument.hybrid_search('anything', model: 'User') }.
        to raise_error(ArgumentError)
    end

    it 'rejects a non-numeric limit' do
      expect {
        User.newsearch('anything', admin_mode: true,
                                   limit: '10; DROP TABLE users')
      }.to raise_error(ArgumentError)
    end

    it 'rejects a non-numeric limit_ratio' do
      expect {
        SearchDocument.hybrid_search('anything', model: User,
                                                 limit_ratio: '3--')
      }.to raise_error(ArgumentError)
    end

    it 'rejects unsupported languages' do
      expect { User.newsearch('anything', language: 'klingon') }.
        to raise_error(ArgumentError)
    end
  end

  context 'rank weights' do
    def query_for(weights: nil)
      SearchDocument.hybrid_search_internal(
        'anything',
        model: User, language: nil, limit: 10, admin_mode: true,
        exact_mode: false, case_sensitive: true, limit_ratio: 3,
        weights: weights
      )[:query]
    end

    it 'ranks with PostgreSQL default weights when none are given' do
      expect(query_for).to include("'{0.1,0.2,0.4,1.0}'::float4[]")
    end

    it 'applies a full weight override in {D,C,B,A} order' do
      sql = query_for(
        weights: { 'A' => 2.0, 'B' => 0.5, 'C' => 0.3, 'D' => 0.05 }
      )
      expect(sql).to include("'{0.05,0.3,0.5,2.0}'::float4[]")
    end

    it 'merges a partial override over the defaults' do
      expect(query_for(weights: { 'C' => 0.05 })).
        to include("'{0.1,0.05,0.4,1.0}'::float4[]")
    end

    it 'rejects a non-numeric weight' do
      expect { query_for(weights: { 'A' => '1); DROP TABLE users' }) }.
        to raise_error(ArgumentError)
    end

    it 'rejects an unrecognised label rather than ignoring it' do
      expect { query_for(weights: { 'E' => 0.5 }) }.
        to raise_error(ArgumentError, /unknown tsvector label/)
    end

    it 'accepts labels given as symbols' do
      expect(query_for(weights: { C: 0.05 })).
        to include("'{0.1,0.05,0.4,1.0}'::float4[]")
    end
  end

  context 'excluding tsvector labels' do
    def query_for(labels, admin_mode: true)
      SearchDocument.hybrid_search_internal(
        'anything',
        model: User, language: nil, limit: 10, admin_mode: admin_mode,
        exact_mode: false, case_sensitive: true, limit_ratio: 3,
        except: labels
      )[:query]
    end

    it 'leaves the query untouched when nothing is excluded' do
      expect(query_for(nil)).to_not include('ts_filter')
    end

    it 'filters the excluded label out of the admin index in admin mode' do
      sql = query_for(['C'])
      expect(sql).to include("ts_filter(admin_content_tsv, '{a,b,d}')")
      expect(sql).to_not include('ts_filter(content_tsv')
    end

    # admin_mode is what says which index the labels belong to, so the same
    # list lands on the other tsvector for a public search.
    it 'filters the excluded label out of the public index otherwise' do
      sql = query_for(['C'], admin_mode: false)
      expect(sql).to include("ts_filter(content_tsv, '{a,b,d}')")
      expect(sql).to_not include('ts_filter(admin_content_tsv')
    end

    it 'keeps the indexable predicate alongside the ts_filter recheck' do
      sql = query_for(['C'])
      expect(sql).to include('@@ admin_content_tsv')
      expect(sql).to include("@@ ts_filter(admin_content_tsv, '{a,b,d}')")
    end

    it 'rejects an unrecognised label' do
      expect { query_for(['E']) }.
        to raise_error(ArgumentError, /unknown tsvector label/)
    end

    it 'rejects excluding every label' do
      expect { query_for(%w[A B C D]) }.
        to raise_error(ArgumentError, /cannot exclude every/)
    end

    it 'accepts a single label given on its own' do
      expect(query_for('C')).
        to include("ts_filter(admin_content_tsv, '{a,b,d}')")
    end

    context 'against indexed records' do
      let!(:bounced) do
        FactoryBot.create(:user, name: 'Bertha Bounce').tap do |u|
          u.record_bounce('mail delivery failed: mailbox zzqxunique full')
        end
      end

      it 'drops records matching only through the excluded label' do
        expect(
          User.newsearch('zzqxunique', admin_mode: true)
        ).to include(bounced)

        expect(
          SearchDocument.hybrid_search(
            'zzqxunique', model: User, admin_mode: true,
                          except: ['C']
          )
        ).to match_array([])
      end

      it 'still matches the record through a label that is kept' do
        expect(
          SearchDocument.hybrid_search(
            'Bertha', model: User, admin_mode: true,
                      except: ['C']
          )
        ).to match_array([bounced])
      end
    end
  end

  context 'exact mode' do
    it 'treats LIKE wildcards in the query as literal characters' do
      legit = FactoryBot.create(:user, name: 'Legitimate 100% Prospect')
      FactoryBot.create(:user, name: 'Someone Else')

      expect(
        User.newsearch('100%', admin_mode: true, exact_mode: true)
      ).to match_array([legit])
      expect(
        User.newsearch('%', admin_mode: true, exact_mode: true)
      ).to match_array([legit])
    end
  end

  context 'de-duplicating records matched via several sections' do
    it 'returns the record once and counts it once' do
      user = FactoryBot.create(:user, name: "Danny Dedupe")
      # the record is indexed on create; add a second section to simulate
      # the multi-part content produced by attachments and similar.
      user.upsert_content('english', 2)
      expect(SearchDocument.where(searchable: user).count).to eq(2)

      results = User.newsearch(
        "Dedupe", admin_mode: true, exact_mode: true, language: 'english'
      )

      expect(results).to match_array([user])
      expect(results.count).to eq(1)
    end
  end

  context 'exact mode case sensitivity' do
    # A partial token ("ASE" inside "Charlotte Case") can only match through
    # exact mode's substring search, never through the tsvector matching.
    # The query is upper-case so it does not match the lower-cased url_name
    # either, isolating the case_sensitive behaviour.
    it 'matches substrings case-sensitively by default' do
      user = FactoryBot.create(:user, name: "Charlotte Case")

      results = SearchDocument.hybrid_search(
        "ASE", model: User, admin_mode: true, exact_mode: true,
               language: 'english'
      )

      expect(results).to be_empty
    end

    it 'matches substrings of any case when case_sensitive is false' do
      user = FactoryBot.create(:user, name: "Charlotte Case")

      results = SearchDocument.hybrid_search(
        "ASE",
        model: User,
        admin_mode: true,
        exact_mode: true,
        case_sensitive: false,
        language: 'english'
      )

      expect(results).to match_array([user])
    end
  end

  context 'searching within a provided base relation' do
    it 'restricts the search to the given relation' do
      with_default_locale(:en) do
        keep = FactoryBot.create(:user, name: "Ria Relation")
        drop = FactoryBot.create(:user, name: "Rory Relation")

        results = SearchDocument.hybrid_search(
          "Relation",
          relation: User.where.not(id: drop.id),
          admin_mode: true,
          language: 'english'
        )

        expect(results).to match_array([keep])
      end
    end

    it 'composes with conditions chained after the search' do
      with_default_locale(:en) do
        a = FactoryBot.create(:user, name: "Charlie Chain")
        b = FactoryBot.create(:user, name: "Chloe Chain")

        results = User.
                  newsearch("Chain", admin_mode: true, language: 'english').
                  where.not(id: b.id)

        expect(results).to match_array([a])
      end
    end
  end
end
