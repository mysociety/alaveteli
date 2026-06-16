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
    it 'delegates to the backend' do
      record = double
      expect(backend).to receive(:reindex_later).with(record)
      Search.reindex_later(record)
    end
  end

  describe '.queued_jobs_count' do
    it 'delegates to the backend' do
      expect(backend).to receive(:queued_jobs_count).and_return(5)
      expect(Search.queued_jobs_count).to eq(5)
    end
  end
end
