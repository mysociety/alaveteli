##
# Contract every Search backend adapter must satisfy. Include it from an
# adapter spec with a `subject` that returns the adapter instance:
#
#   RSpec.describe Search::Adapters::Xapian::Adapter, :xapian do
#     subject(:adapter) { described_class.new }
#     it_behaves_like 'a search backend'
#   end
#
# It exercises the backend-agnostic interface against real fixture data, so
# the including spec must run with an indexed backend (e.g. tagged :xapian).
RSpec.shared_examples 'a search backend' do
  # Backends that only index some models privately (e.g. PostgreSQL indexes
  # users in the admin index) can supply the options needed to search them.
  let(:search_scope_options) { {} }

  describe '#search_scope' do
    it 'returns an ActiveRecord::Relation' do
      scope = adapter.search_scope('bob', User.all, **search_scope_options)
      expect(scope).to be_a(ActiveRecord::Relation)
    end

    it 'constrains the relation to matching records' do
      scope = adapter.search_scope('bob', User.all, **search_scope_options)
      expect(scope).to include(users(:bob_smith_user))
    end

    it 'keeps the relation chainable with further conditions' do
      bob = users(:bob_smith_user)
      scope = adapter.search_scope('bob', User.all, **search_scope_options).
              where.not(id: bob.id)
      expect(scope).not_to include(bob)
    end

    it 'respects conditions already applied to the relation' do
      bob = users(:bob_smith_user)
      scope = adapter.search_scope(
        'bob', User.where.not(id: bob.id), **search_scope_options
      )
      expect(scope).not_to include(bob)
    end
  end

  describe '#search' do
    it 'returns a searcher whose #results is a Search::Results' do
      searcher = subject.search('bob', models: [User])
      results = searcher.results(page: 1, per_page: 25)
      expect(results).to be_a(Search::Results)
    end

    it 'accepts the ranking options callers pass' do
      searcher = subject.search(
        'bob', models: [User],
        sort_by: nil, sort_ascending: true, collapse_by: nil
      )
      expect { searcher.results(page: 1, per_page: 25) }.not_to raise_error
    end
  end

  describe '#request_search' do
    it 'returns a searcher whose results are InfoRequests' do
      results = subject.request_search('test').results(page: 1, per_page: 25)
      expect(results).to be_a(Search::Results)
      expect(results.results.map { |r| r[:model] }).to all(be_a(InfoRequest))
    end
  end

  describe '#reindex_later' do
    it 'accepts a record without raising' do
      expect { subject.reindex_later(users(:bob_smith_user)) }.
        not_to raise_error
    end
  end

  describe '#queued_jobs_count' do
    it 'returns an Integer' do
      expect(subject.queued_jobs_count).to be_a(Integer)
    end
  end
end
