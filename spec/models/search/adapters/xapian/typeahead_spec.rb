require 'spec_helper'

RSpec.describe Search::Adapters::Xapian::Typeahead, :xapian do
  describe '#initialize' do
    it 'stores the query string and model' do
      ta = described_class.new('test', model: PublicBody)
      expect(ta.query_string).to eq('test')
      expect(ta.model).to eq(PublicBody)
    end

    it 'defaults exclude_tags to empty array' do
      ta = described_class.new('test', model: PublicBody)
      expect(ta.exclude_tags).to eq([])
    end
  end

  describe '#results' do
    it 'returns a Search::Results object' do
      ta = described_class.new('geraldine', model: PublicBody)
      results = ta.results(page: 1, per_page: 25)
      expect(results).to be_a(Search::Results)
    end

    it 'finds matching bodies' do
      ta = described_class.new('geraldine', model: PublicBody)
      results = ta.results(page: 1, per_page: 25)
      models = results.items.map { |r| r[:model] }
      expect(models).to include(public_bodies(:geraldine_public_body))
    end

    it 'returns empty results for blank queries' do
      ta = described_class.new('', model: PublicBody)
      results = ta.results(page: 1, per_page: 25)
      expect(results.items).to be_empty
      expect(results.total_estimate).to eq(0)
    end

    it 'returns empty results for short queries' do
      ta = described_class.new('a', model: PublicBody)
      results = ta.results(page: 1, per_page: 25)
      expect(results.items).to be_empty
    end

    it 'excludes results matching exclude_tags' do
      ta = described_class.new(
        'lonely', model: PublicBody,
                  exclude_tags: ['lonely_agency']
      )
      results = ta.results(page: 1, per_page: 25)
      expect(results.items).to be_empty
    end
  end
end
