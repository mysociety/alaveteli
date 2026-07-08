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

    it 'forwards the backend option for the facade to resolve' do
      expect(Search).to receive(:search_scope).
        with('bob', kind_of(ActiveRecord::Relation),
             backend: :postgresql, admin_mode: true)
      User.search_scope('bob', backend: :postgresql, admin_mode: true)
    end
  end
end

RSpec.describe Searchable, 'index lifecycle' do
  it 'indexes a record when it is created' do
    user = FactoryBot.create(:user)
    expect(user.search_documents.count).to eq(1)
  end

  it 'refreshes indexed content when a record is updated' do
    user = FactoryBot.create(:user, name: 'Original Name')
    user.update!(name: 'Updated Name')

    content = user.search_documents.reload.first.raw_admin_content
    expect(content).to include('Updated Name')
    expect(content).not_to include('Original Name')
  end

  it 'removes search documents when the record is destroyed' do
    user = FactoryBot.create(:user)
    expect { user.destroy! }.to change(SearchDocument, :count).by(-1)
  end

  it 'does not index models that are not registered as searchable' do
    body = FactoryBot.create(:public_body)
    expect(body.search_documents.count).to eq(0)
  end

  describe '.reindex_all' do
    it 'indexes every indexable record' do
      FactoryBot.create_list(:user, 2)
      SearchDocument.delete_all

      User.reindex_all

      expect(
        SearchDocument.where(searchable_type: 'User').count
      ).to eq(User.count)
    end
  end
end
