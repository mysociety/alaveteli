require 'spec_helper'
require_relative '../shared_examples/backend_contract'

RSpec.describe Search::Adapters::Postgresql::Adapter, :postgresql do
  subject(:adapter) { described_class.new }

  it_behaves_like 'a scoped search backend' do
    # Users are only indexed in the admin index, so searching them needs
    # admin mode.
    let(:search_scope_options) { { admin_mode: true } }
  end

  it_behaves_like 'a request search backend'

  describe '#search_scope' do
    it 'passes case_sensitive through to the exact match search' do
      user = FactoryBot.create(:user, name: 'Charlotte Case')

      scope = adapter.search_scope(
        'ASE', User.all,
        admin_mode: true, exact_mode: true, case_sensitive: false
      )

      expect(scope).to include(user)
    end
  end

  describe '#request_search' do
    let!(:older) do
      FactoryBot.create(:info_request, title: 'Ptarmigan ptarmigan',
                                       created_at: 2.days.ago)
    end
    let!(:newer) { FactoryBot.create(:info_request, title: 'Ptarmigan') }

    def request_search(**options)
      adapter.request_search('ptarmigan', **options).
        results(page: 1, per_page: 25).map { |result| result[:model] }
    end

    it 'puts the best match first by default' do
      expect(request_search).to eq([older, newer])
    end

    it 'puts the newest first when sorting ascending, as Xapian does' do
      expect(request_search(sort_by: 'created_at', sort_ascending: true)).
        to eq([newer, older])
    end

    it 'puts the oldest first when sorting descending' do
      expect(request_search(sort_by: 'created_at', sort_ascending: false)).
        to eq([older, newer])
    end

    it 'puts requests with no events last when sorting by description' do
      older.update_column(:last_event_time, nil)
      newer.update_column(:last_event_time, 1.day.ago)

      expect(request_search(sort_by: 'described_at')).to eq([newer, older])
    end

    it 'counts every matching request' do
      results = adapter.request_search('ptarmigan').
                results(page: 1, per_page: 1)
      expect(results.matches_estimated).to eq(2)
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
