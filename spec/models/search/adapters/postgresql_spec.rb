require 'spec_helper'
require_relative '../shared_examples/backend_contract'

RSpec.describe Search::Adapters::Postgresql::Adapter, :postgresql do
  subject(:adapter) { described_class.new }

  it_behaves_like 'a scoped search backend' do
    # Users are only indexed in the admin index, so searching them needs
    # admin mode.
    let(:search_scope_options) { { admin_mode: true } }
  end

  describe '#reindex_later' do
    it 'reindexes the record inline' do
      user = users(:bob_smith_user)
      expect(user).to receive(:reindex)
      adapter.reindex_later(user)
    end
  end
end
