require 'spec_helper'

RSpec.describe Search::Adapters::Xapian::FullTextSearch, :xapian do
  describe '#initialize' do
    it 'stores the query string' do
      fts = described_class.new('test', models: [InfoRequestEvent])
      expect(fts.query_string).to eq('test')
    end

    it 'wraps models in an array' do
      fts = described_class.new('test', models: InfoRequestEvent)
      expect(fts.models).to eq([InfoRequestEvent])
    end
  end

  describe '#results' do
    it 'returns a Search::Results object' do
      fts = described_class.new('bob', models: [User])
      results = fts.results(page: 1, per_page: 25)
      expect(results).to be_a(Search::Results)
    end

    it 'finds matching records' do
      fts = described_class.new('bob', models: [User])
      results = fts.results(page: 1, per_page: 25)
      models = results.items.map { |r| r[:model] }
      expect(models).to include(users(:bob_smith_user))
    end

    it 'sets the total estimate' do
      fts = described_class.new('bob', models: [User])
      results = fts.results(page: 1, per_page: 25)
      expect(results.total_estimate).to be >= 1
    end

    it 'sets current_page and per_page' do
      fts = described_class.new('bob', models: [User])
      results = fts.results(page: 2, per_page: 5)
      expect(results.current_page).to eq(2)
      expect(results.per_page).to eq(5)
    end

    it 'includes spelling correction' do
      fts = described_class.new('rob', models: [User])
      results = fts.results(page: 1, per_page: 5)
      expect(results.spelling_correction).to eq('bob')
    end

    it 'includes words to highlight' do
      fts = described_class.new('bob', models: [User])
      results = fts.results(page: 1, per_page: 5)
      expect(results.words_to_highlight).to be_present
    end

    it 'reports has_normal_search_terms' do
      fts = described_class.new('bob', models: [User])
      results = fts.results(page: 1, per_page: 5)
      expect(results).to have_normal_search_terms
    end

    it 'searches across multiple model types' do
      models = [User, PublicBody, InfoRequestEvent]
      fts = described_class.new('Bob', models: models)
      results = fts.results(page: 1, per_page: 25)
      classes = results.items.map { |r| r[:model].class }.uniq
      expect(classes.size).to be > 1
    end

    it 'respects sort_by_prefix' do
      fts = described_class.new(
        'request:why_do_you_have_such_a_fancy_dog',
        models: [InfoRequestEvent],
        sort_by_prefix: 'created_at',
        sort_by_ascending: true
      )
      results = fts.results(page: 1, per_page: 25)
      expect(results.items.size).to eq(3)
    end

    it 'respects collapse_by_prefix' do
      fts_uncollapsed = described_class.new(
        'request:why_do_you_have_such_a_fancy_dog',
        models: [InfoRequestEvent]
      )
      fts_collapsed = described_class.new(
        'request:why_do_you_have_such_a_fancy_dog',
        models: [InfoRequestEvent],
        collapse_by_prefix: 'request_collapse'
      )

      uncollapsed = fts_uncollapsed.results(page: 1, per_page: 25)
      collapsed = fts_collapsed.results(page: 1, per_page: 25)

      expect(uncollapsed.items.size).to eq(3)
      expect(collapsed.items.size).to eq(1)
    end
  end
end
