require 'spec_helper'
require_relative '../shared_examples/backend_contract'

RSpec.describe Search::Adapters::Postgresql::Adapter, :postgresql do
  subject(:adapter) { described_class.new }

  it_behaves_like 'a search backend' do
    # Users are only indexed in the admin index, so searching them needs
    # admin mode.
    let(:search_scope_options) { { admin_mode: true } }
  end

  describe '#search' do
    it 'returns results wrapped in Search::Results' do
      results = adapter.search('bob', models: [User], admin_mode: true).
                results(page: 1, per_page: 25)
      expect(results).to be_a(Search::Results)
      expect(results.results.map { |r| r[:model] }).
        to include(users(:bob_smith_user))
    end

    it 'raises on a true multi-model search' do
      expect { adapter.search('x', models: [User, PublicBody]) }.
        to raise_error(ArgumentError)
    end
  end

  describe '#typeahead' do
    it 'matches public bodies by prefix' do
      body = public_bodies(:geraldine_public_body)

      results = adapter.typeahead('gerald', model: PublicBody).
                results(page: 1, per_page: 10)

      expect(results.results.map { |r| r[:model] }).to include(body)
    end
  end

  describe '#similar' do
    it 'returns Search::Results without raising' do
      request = FactoryBot.create(:info_request)
      expect(adapter.similar(request).results).to be_a(Search::Results)
    end
  end

  describe '#reindex_later' do
    it 'reindexes the record inline' do
      user = users(:bob_smith_user)
      expect(user).to receive(:reindex)
      adapter.reindex_later(user)
    end
  end
end
