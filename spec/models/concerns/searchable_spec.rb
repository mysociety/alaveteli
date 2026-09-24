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

  it 'roots a record with no parent at itself' do
    user = FactoryBot.create(:user)
    expect(user.search_documents.map(&:root)).to eq([user])
  end

  it 'roots a record at the top of its tree' do
    info_request = FactoryBot.create(:info_request)
    message = info_request.outgoing_messages.first

    expect(message.search_documents.map(&:root)).to eq([info_request])
  end

  it 'does not index models that are not registered as searchable' do
    n = FactoryBot.create(:notification)
    expect(SearchDocument.where(searchable_type: "Notification").count).to eq(0)
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

    it 'reads models with ruby attributes one record at a time' do
      expect(PublicBody).not_to receive(:reindex_all_inside_db)
      PublicBody.reindex_all
    end

    it 'builds the documents inside the database for column only models' do
      FactoryBot.create(:user)
      SearchDocument.delete_all

      expect(User).to receive(:reindex_all_inside_db).and_call_original
      User.reindex_all

      expect(SearchDocument.where(searchable_type: 'User')).to be_any
    end

    it 'leaves the other partitions alone' do
      FactoryBot.create(:public_body)
      body_documents = SearchDocument.where(searchable_type: 'PublicBody').count

      User.reindex_all

      expect(
        SearchDocument.where(searchable_type: 'PublicBody').count
      ).to eq(body_documents)
    end

    it 'skips records the indexable scope filters out' do
      banned = FactoryBot.create(:user, ban_text: 'Spammer')
      allow(User).to receive(:indexable).
        and_return(User.where.not(id: banned.id))

      User.reindex_all

      expect(
        SearchDocument.where(searchable_type: 'User', searchable_id: banned.id)
      ).to be_empty
    end

    it 'builds the root inside the database from a belongs_to' do
      message = FactoryBot.create(:initial_request)
      SearchDocument.delete_all
      allow(OutgoingMessage).to receive(:search_options).
        and_return(index: { body: 'A' }, root: :info_request)

      expect(OutgoingMessage).to receive(:reindex_all_inside_db).
        and_call_original
      OutgoingMessage.reindex_all

      expect(message.search_documents.map(&:root)).
        to eq([message.info_request])
    end

    it 'reads the record when the root is not a belongs_to' do
      allow(User).to receive(:search_options).
        and_return(index: { name: 'A' }, root: :profile_photo)

      expect(User).not_to receive(:reindex_all_inside_db)
      User.reindex_all
    end

    it 'reads the record when a model decides publicly_searchable? itself' do
      allow(User).to receive(:public_split_in_database?).and_return(false)

      expect(User).not_to receive(:reindex_all_inside_db)
      User.reindex_all
    end

    it 'splits the public content by prominence inside the database' do
      shown = FactoryBot.create(:info_request, title: 'Plain sight')
      hidden = FactoryBot.create(:hidden_request, title: 'Out of sight')
      SearchDocument.delete_all

      InfoRequest.reindex_all

      documents = SearchDocument.where(searchable_type: 'InfoRequest')
      expect(documents.find_by(searchable_id: shown.id)).
        to have_attributes(raw_content: a_string_including('Plain sight'))
      expect(documents.find_by(searchable_id: hidden.id)).
        to have_attributes(
          raw_content: nil,
          raw_admin_content: a_string_including('Out of sight')
        )
    end

    it 'copies the indexed columns into the raw content' do
      user = FactoryBot.create(:user, name: 'Winston Smith')

      User.reindex_all

      document = SearchDocument.find_by(searchable_type: 'User',
                                        searchable_id: user.id)
      expect(document.raw_admin_content).to include('Winston Smith')
      expect(User.newsearch('Winston Smith', admin_mode: true)).to eq([user])
    end
  end
end

RSpec.describe Searchable, 'public content' do
  let(:document) { info_request.search_documents.reload.first }

  context 'with normal prominence' do
    let(:info_request) do
      FactoryBot.create(:info_request, title: 'Plain sight')
    end

    it 'goes in the public index' do
      expect(document.raw_content).to include('Plain sight')
      expect(document.raw_admin_content).not_to include('Plain sight')
    end
  end

  context 'with any other prominence' do
    let(:info_request) do
      FactoryBot.create(:backpage_request, title: 'Back page')
    end

    it 'goes in the admin index instead' do
      expect(document.raw_content).to be_nil
      expect(document.raw_admin_content).to include('Back page')
    end
  end

  context 'under an embargo' do
    let(:info_request) do
      FactoryBot.create(:embargoed_request, title: 'Under wraps')
    end

    it 'stays in the public index' do
      expect(document.raw_content).to include('Under wraps')
    end
  end

  context 'when the prominence changes' do
    let(:info_request) do
      FactoryBot.create(:info_request, title: 'On the move')
    end

    it 'moves between the indexes' do
      expect { info_request.update!(prominence: 'hidden') }.
        to change { document.reload.raw_content }.
        from(a_string_including('On the move')).to(nil).
        and change { document.reload.raw_admin_content }.
        to(a_string_including('On the move'))
    end
  end
end
