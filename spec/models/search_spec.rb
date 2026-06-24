require 'spec_helper'

RSpec.describe Search do
  before do
    @original_backend = Search.backend
    @original_index_backends = Search.index_backends
    Search.backend = instance_double(Search::Backend)
    Search.index_backends = [Search.backend]
  end

  after do
    Search.backend = @original_backend
    Search.index_backends = @original_index_backends
  end

  let(:backend) { Search.backend }

  describe '.backend' do
    it 'returns the configured backend' do
      expect(Search.backend).to eq(backend)
    end
  end

  describe '.index_backends' do
    it 'defaults to the query backend' do
      Search.instance_variable_set(:@index_backends, nil)
      expect(Search.index_backends).to eq([Search.backend])
    end

    it 'can be assigned a list of backends' do
      other = instance_double(Search::Backend)
      Search.index_backends = [backend, other]
      expect(Search.index_backends).to eq([backend, other])
    end

    it 'wraps a single backend in an array' do
      Search.index_backends = backend
      expect(Search.index_backends).to eq([backend])
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

    it 'defaults SEARCH_INDEX_BACKENDS to xapian only' do
      expect(AlaveteliConfiguration.search_index_backends).to eq(['xapian'])
    end
  end

  describe '.use_configured_backends!' do
    it 'sets the query and index backends from configuration' do
      allow(AlaveteliConfiguration).to receive(:search_backend).
        and_return('xapian')
      allow(AlaveteliConfiguration).to receive(:search_index_backends).
        and_return(%w[xapian postgresql])

      Search.use_configured_backends!

      expect(Search.backend).to be_a(Search::Adapters::Xapian::Adapter)
      expect(Search.index_backends.map(&:class)).to eq(
        [Search::Adapters::Xapian::Adapter,
         Search::Adapters::Postgresql::Adapter]
      )
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
  end

  describe '.request_search' do
    it 'delegates to the backend' do
      expect(backend).to receive(:request_search).with('test')
      Search.request_search('test')
    end
  end

  describe '.search_scope' do
    it 'delegates to the backend' do
      relation = User.all
      expect(backend).to receive(:search_scope).with('test', relation)
      Search.search_scope('test', relation)
    end
  end

  describe '.typeahead' do
    it 'delegates to the backend' do
      expect(backend).to receive(:typeahead).with(
        'test', model: PublicBody, page: 1
      )
      Search.typeahead('test', model: PublicBody, page: 1)
    end
  end

  describe '.similar' do
    it 'delegates to the backend' do
      record = double
      expect(backend).to receive(:similar).with(record)
      Search.similar(record)
    end
  end

  describe '.reindex_later' do
    it 'indexes every backend' do
      other = instance_double(Search::Backend)
      Search.index_backends = [backend, other]
      record = double
      expect(backend).to receive(:reindex_later).with(record)
      expect(other).to receive(:reindex_later).with(record)
      Search.reindex_later(record)
    end
  end

  describe '.queued_jobs_count' do
    it 'sums the count across every index backend' do
      other = instance_double(Search::Backend)
      Search.index_backends = [backend, other]
      allow(backend).to receive(:queued_jobs_count).and_return(5)
      allow(other).to receive(:queued_jobs_count).and_return(3)
      expect(Search.queued_jobs_count).to eq(8)
    end
  end
end
