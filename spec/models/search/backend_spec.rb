require 'spec_helper'

RSpec.describe Search::Backend do
  subject(:backend) { described_class.new }

  describe '#search' do
    it 'raises NotImplementedError' do
      expect { backend.search('query', models: [User]) }.to raise_error(
        NotImplementedError, 'Subclasses must implement #search'
      )
    end
  end

  describe '#search_scope' do
    it 'raises NotImplementedError' do
      expect { backend.search_scope('query', User.all) }.to raise_error(
        NotImplementedError, 'Subclasses must implement #search_scope'
      )
    end
  end

  describe '#typeahead' do
    it 'raises NotImplementedError' do
      expect { backend.typeahead('query', model: User) }.to raise_error(
        NotImplementedError, 'Subclasses must implement #typeahead'
      )
    end
  end

  describe '#similar' do
    it 'raises NotImplementedError' do
      expect { backend.similar(double) }.to raise_error(
        NotImplementedError, 'Subclasses must implement #similar'
      )
    end
  end

  describe '#reindex_later' do
    it 'returns nil' do
      expect(backend.reindex_later(double)).to be_nil
    end
  end

  describe '#queued_jobs_count' do
    it 'returns 0' do
      expect(backend.queued_jobs_count).to eq(0)
    end
  end
end
