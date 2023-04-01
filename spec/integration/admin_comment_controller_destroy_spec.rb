require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe 'Destroying a Comment' do
  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)

    confirm(:admin_user)
    @admin = login(:admin_user)

    @comment = FactoryBot.create(:comment, :with_event, body: 'PII')
    @comment.reindex_request_events
    update_xapian_index
  end

  it 'destroing a comment removes it from the search index' do
    # prove the comment is in the search index
    using_session(without_login) do
      visit search_requests_path(query: 'PII')
      expect(page).to have_content('One FOI request found')
      expect(page).to have_selector('.results_block div', text: 'PII')
    end

    # remove the comment via the admin UI
    using_session(@admin) do
      visit edit_admin_comment_path(@comment)
      find('form input[value="Destroy comment"]').click
    end

    # run the search indexing update manually
    update_xapian_index

    # show the comment has been removed from the search index
    using_session(without_login) do
      visit search_requests_path(query: 'PII')
      expect(page).to have_content('There were no results matching your query.')
      expect(page).to_not have_selector('.results_block div', text: 'PII')
    end
  end
end
