require 'spec_helper'

RSpec.describe Search do
  before do
    @original_backend = Search.backend
    Search.backend = instance_double(Search::Backend)
  end

  after do
    Search.backend = @original_backend
  end

  let(:backend) { Search.backend }

  describe '.backend' do
    it 'returns the configured backend' do
      expect(Search.backend).to eq(backend)
    end
  end

  describe '.backend_for' do
    it 'builds the registered adapter for a name' do
      expect(Search.backend_for('xapian')).
        to be_a(Search::Adapters::Xapian::Adapter)
    end

    it 'accepts a symbol name' do
      expect(Search.backend_for(:xapian)).
        to be_a(Search::Adapters::Xapian::Adapter)
    end

    it 'builds the Postgresql adapter for postgresql' do
      expect(Search.backend_for('postgresql')).
        to be_a(Search::Adapters::Postgresql::Adapter)
    end

    it 'raises for an unknown backend' do
      expect { Search.backend_for('bogus') }.
        to raise_error(ArgumentError, /Unknown search backend/)
    end
  end

  describe 'default configuration' do
    it 'defaults SEARCH_BACKEND to xapian' do
      expect(AlaveteliConfiguration.search_backend).to eq('xapian')
    end
  end

  describe '.use_configured_backend!' do
    it 'sets the query backend from configuration' do
      allow(AlaveteliConfiguration).to receive(:search_backend).
        and_return('xapian')

      Search.use_configured_backend!

      expect(Search.backend).to be_a(Search::Adapters::Xapian::Adapter)
    end
  end

  describe '.context' do
    it 'returns an InfoRequest context when given an info_request' do
      request = double
      context = Search.context(info_request: request)
      expect(context).to be_a(Search::Context::InfoRequest)
      expect(context.info_request).to eq(request)
    end

    it 'returns nil without arguments' do
      expect(Search.context).to be_nil
    end
  end

  describe '.search' do
    it 'delegates to the backend' do
      expect(backend).to receive(:search).with(
        'test', models: [PublicBody], page: 1
      )
      Search.search('test', models: [PublicBody], page: 1)
    end

    it 'delegates to the named backend without the backend option' do
      other = instance_double(Search::Backend)
      allow(Search).to receive(:backend_for).with(:postgresql).
        and_return(other)
      expect(other).to receive(:search).with('test', models: [PublicBody])
      Search.search('test', models: [PublicBody], backend: :postgresql)
    end
  end

  describe '.search_scope' do
    it 'delegates to the backend' do
      relation = User.all
      expect(backend).to receive(:search_scope).with('test', relation)
      Search.search_scope('test', relation)
    end

    it 'delegates to the named backend without the backend option' do
      relation = User.all
      other = instance_double(Search::Backend)
      allow(Search).to receive(:backend_for).with(:postgresql).
        and_return(other)
      expect(other).to receive(:search_scope).
        with('test', relation, admin_mode: true)
      Search.search_scope(
        'test', relation, backend: :postgresql, admin_mode: true
      )
    end

    it 'raises for an unknown backend name' do
      expect { Search.search_scope('test', User.all, backend: :bogus) }.
        to raise_error(ArgumentError, /Unknown search backend/)
    end
  end

  describe '.typeahead' do
    it 'delegates to the backend' do
      expect(backend).to receive(:typeahead).with(
        'test', model: PublicBody, page: 1
      )
      Search.typeahead('test', model: PublicBody, page: 1)
    end

    it 'delegates to the named backend without the backend option' do
      other = instance_double(Search::Backend)
      allow(Search).to receive(:backend_for).with(:postgresql).
        and_return(other)
      expect(other).to receive(:typeahead).with('test', model: PublicBody)
      Search.typeahead('test', model: PublicBody, backend: :postgresql)
    end
  end

  describe '.similar' do
    it 'delegates to the backend' do
      record = double
      expect(backend).to receive(:similar).with(record)
      Search.similar(record)
    end

    it 'delegates to the named backend' do
      record = double
      other = instance_double(Search::Backend)
      allow(Search).to receive(:backend_for).with(:postgresql).
        and_return(other)
      expect(other).to receive(:similar).with(record)
      Search.similar(record, backend: :postgresql)
    end
  end

  describe '.reindex_later' do
    it 'indexes every registered backend' do
      xapian = instance_double(Search::Backend)
      postgresql = instance_double(Search::Backend)
      allow(Search).to receive(:backend_for).with(:xapian).and_return(xapian)
      allow(Search).to receive(:backend_for).
        with(:postgresql).and_return(postgresql)
      record = double
      expect(xapian).to receive(:reindex_later).with(record)
      expect(postgresql).to receive(:reindex_later).with(record)
      Search.reindex_later(record)
    end
  end

  describe '.queued_jobs_count' do
    it 'sums the count across every registered backend' do
      xapian = instance_double(Search::Backend)
      postgresql = instance_double(Search::Backend)
      allow(Search).to receive(:backend_for).with(:xapian).and_return(xapian)
      allow(Search).to receive(:backend_for).
        with(:postgresql).and_return(postgresql)
      allow(xapian).to receive(:queued_jobs_count).and_return(5)
      allow(postgresql).to receive(:queued_jobs_count).and_return(3)
      expect(Search.queued_jobs_count).to eq(8)
    end
  end
end
