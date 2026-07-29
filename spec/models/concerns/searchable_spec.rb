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

    it 'resolves excluded field names to labels for the backend' do
      expect(Search).to receive(:search_scope).
        with('bob', kind_of(ActiveRecord::Relation),
             admin_mode: true, except: ['C'])
      User.search_scope('bob', admin_mode: true,
                               except: [:email_bounce_message])
    end

    it 'resolves the names against the index the search will read' do
      expect { User.search_scope('bob', except: [:email_bounce_message]) }.
        to raise_error(ArgumentError, /does not index/)
    end
  end

  describe '.except_labels_for' do
    it 'resolves a field name to the label it is weighted with' do
      expect(User.except_labels_for([:email_bounce_message],
                                    admin_mode: true)).to eq(['C'])
    end

    it 'accepts field names given as strings' do
      expect(User.except_labels_for(['email_bounce_message'],
                                    admin_mode: true)).to eq(['C'])
    end

    it 'resolves a single field given on its own' do
      expect(User.except_labels_for(:email_bounce_message,
                                    admin_mode: true)).to eq(['C'])
    end

    it 'returns nothing to exclude when given no fields' do
      expect(User.except_labels_for(nil, admin_mode: true)).to eq([])
      expect(User.except_labels_for([], admin_mode: true)).to eq([])
    end

    it 'rejects a field the model does not index' do
      expect { User.except_labels_for([:no_such_field], admin_mode: true) }.
        to raise_error(ArgumentError, /does not index no_such_field/)
    end

    it 'rejects a field the searched index does not carry' do
      # email_bounce_message is only in the admin index, so a public search
      # has nothing to exclude and asking is a mistake rather than a no-op.
      expect { User.except_labels_for([:email_bounce_message]) }.
        to raise_error(ArgumentError,
                       /does not index email_bounce_message in index/)
    end

    it 'rejects a field whose weight also carries a field being kept' do
      # email, name, url_name, ban_text and about_me all share weight A, so
      # dropping A would drop all of them.
      expect { User.except_labels_for([:email], admin_mode: true) }.
        to raise_error(ArgumentError, /also carries/)
    end

    it 'accepts fields that between them cover the whole weight' do
      expect(
        User.except_labels_for(
          %i[email name url_name ban_text about_me], admin_mode: true
        )
      ).to eq(['A'])
    end

    it 'raises for models that have not been made searchable' do
      expect { Comment.except_labels_for([:body]) }.
        to raise_error(NotImplementedError)
    end

    context 'for a model indexing both publicly and for admins' do
      let(:model) do
        stub_const('DualIndexed', Class.new do
          extend Searchable::SearchableMethods

          def self.name
            'DualIndexed'
          end
        end)
      end

      before do
        # title shares weight A with notes in the admin index, but has A to
        # itself in the public one.
        model.searchable index: { title: 'A', body: 'B' },
                         admin_index: { title: 'A', notes: 'A' }
      end

      after do
        Searchable.class_variable_get(:@@searchable_models).
          delete('DualIndexed')
      end

      it 'ignores the admin index when resolving a public search' do
        expect(model.except_labels_for([:title])).to eq(['A'])
      end

      it 'ignores the public index when resolving an admin search' do
        expect(model.except_labels_for([:notes, :title], admin_mode: true)).
          to eq(['A'])
      end

      it 'resolves the same field to each index separately' do
        expect(model.except_labels_for([:body])).to eq(['B'])
        expect { model.except_labels_for([:body], admin_mode: true) }.
          to raise_error(ArgumentError, /does not index body in admin_index/)
      end

      it 'still rejects a shared weight within the searched index' do
        expect { model.except_labels_for([:title], admin_mode: true) }.
          to raise_error(ArgumentError, /also carries notes/)
      end
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
