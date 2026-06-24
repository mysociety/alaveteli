require 'spec_helper'

RSpec.describe Searchable, :xapian do
  describe '.search_scope' do
    it 'returns a chainable ActiveRecord::Relation' do
      scope = User.search_scope('bob')
      expect(scope).to be_a(ActiveRecord::Relation)
      expect(scope).to include(users(:bob_smith_user))
    end

    it 'composes with conditions applied before the search' do
      bob = users(:bob_smith_user)
      scope = User.where.not(id: bob.id).search_scope('bob')
      expect(scope).not_to include(bob)
    end

    it 'composes with conditions applied after the search' do
      bob = users(:bob_smith_user)
      scope = User.search_scope('bob').where.not(id: bob.id)
      expect(scope).not_to include(bob)
    end

    it 'is available on every indexed model' do
      expect(PublicBody).to respond_to(:search_scope)
      expect(InfoRequestEvent).to respond_to(:search_scope)
    end

    it 'forwards options through to the search backend' do
      expect(Search).to receive(:search_scope).
        with('bob', kind_of(ActiveRecord::Relation), admin_mode: true)
      User.search_scope('bob', admin_mode: true)
    end
  end
end

RSpec.describe Searchable do
  describe '.searchable_models' do
    it 'returns the registered models as classes' do
      expect(described_class.searchable_models).
        to include(PublicBody, InfoRequestEvent)
    end
  end

  describe '.not_indexed', :postgresql do
    let(:body) { public_bodies(:geraldine_public_body) }

    it 'excludes records that already have a search document' do
      # the :postgresql hook has already indexed every public body
      expect(PublicBody.not_indexed).not_to include(body)
    end

    it 'includes records without a search document' do
      SearchDocument.delete_all
      expect(PublicBody.not_indexed).to include(body)
    end

    it 'excludes a record once it has been reindexed' do
      SearchDocument.delete_all
      body.reindex
      expect(PublicBody.not_indexed).not_to include(body)
    end
  end

  describe '.reindex_record', :postgresql do
    let(:body) { public_bodies(:geraldine_public_body) }

    it 'reindexes the record and returns true' do
      SearchDocument.delete_all
      expect(PublicBody.reindex_record(body)).to be(true)
      expect(PublicBody.not_indexed).not_to include(body)
    end

    it 'logs and returns false when the record fails to reindex' do
      allow(body).to receive(:reindex).and_raise(StandardError, 'boom')
      expect(Rails.logger).to receive(:error).
        with(/Failed to reindex PublicBody/)
      expect(PublicBody.reindex_record(body)).to be(false)
    end
  end
end
