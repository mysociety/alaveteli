require 'spec_helper'

describe Admin::OutgoingMessages::SnippetsController do
  before(:each) { basic_auth_login(@request) }

  describe 'GET #index' do
    let!(:snippets) do
      3.times.map { FactoryBot.create(:outgoing_message_snippet) }
    end

    before { get :index }

    it 'returns a successful response' do
      expect(response).to be_successful
    end

    it 'assigns a page title' do
      expect(assigns[:title]).to eq('Listing Snippets')
    end

    it 'collects snippets' do
      expect(assigns[:snippets]).to match_array(snippets)
    end

    it 'renders the correct template' do
      expect(response).to render_template('index')
    end
  end
end
