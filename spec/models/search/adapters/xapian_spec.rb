require 'spec_helper'

RSpec.describe Search::Adapters::Xapian::Adapter, :xapian do
  subject(:adapter) { described_class.new }

  describe '#search_scope' do
    it 'returns an ActiveRecord::Relation' do
      scope = adapter.search_scope('bob', User.all)
      expect(scope).to be_a(ActiveRecord::Relation)
    end

    it 'constrains the relation to matching records' do
      scope = adapter.search_scope('bob', User.all)
      expect(scope).to include(users(:bob_smith_user))
    end

    it 'keeps the relation chainable with further conditions' do
      bob = users(:bob_smith_user)
      scope = adapter.search_scope('bob', User.all).where.not(id: bob.id)
      expect(scope).not_to include(bob)
    end

    it 'respects conditions already applied to the relation' do
      bob = users(:bob_smith_user)
      scope = adapter.search_scope('bob', User.where.not(id: bob.id))
      expect(scope).not_to include(bob)
    end
  end
end
