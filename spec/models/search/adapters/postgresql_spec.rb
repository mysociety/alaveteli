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

    it 'searches across several models at once' do
      body = FactoryBot.create(:public_body, name: 'Zarquon Authority')
      body.reindex
      user = FactoryBot.create(:user, name: 'Zarquon Person')
      user.reindex

      results = adapter.
                search('Zarquon', models: [PublicBody, User], admin_mode: true).
                results(page: 1, per_page: 25)

      records = results.results.map { |r| r[:model] }
      expect(records).to include(body)
      expect(records).to include(user)
    end

    it 'collapses results to one per request when asked' do
      request = FactoryBot.create(:info_request, title: 'Wibblefitz Inquiry')
      message = request.outgoing_messages.first
      message.update!(body: 'Wibblefitz details of the matter')
      [request, message].each(&:reindex)

      models = [InfoRequest, OutgoingMessage]

      uncollapsed = adapter.search('Wibblefitz', models: models).
                    results(page: 1, per_page: 25).results
      collapsed = adapter.
                  search('Wibblefitz', models: models,
                                       collapse_by: 'request_collapse').
                  results(page: 1, per_page: 25).results

      expect(uncollapsed.size).to be > 1
      expect(collapsed.size).to eq(1)
      expect(collapsed.first[:model]).to eq(request)
    end

    it 'exposes the query terms to highlight' do
      results = adapter.search('geraldine quango', models: [PublicBody]).
                results(page: 1, per_page: 10)

      expect(results.words_to_highlight).to include('geraldine', 'quango')
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
