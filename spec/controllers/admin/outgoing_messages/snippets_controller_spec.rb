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

  describe 'GET edit' do
    let!(:snippet) { FactoryBot.create(:outgoing_message_snippet) }

    before { get :edit, params: { id: snippet.id } }

    it 'returns a successful response' do
      expect(response).to be_successful
    end

    it 'assigns a page title' do
      expect(assigns[:title]).to eq('Edit snippet')
    end

    it 'assigns the snippet' do
      expect(assigns[:snippet]).to eq(snippet)
    end

    it 'renders the correct template' do
      expect(response).to render_template(:edit)
    end
  end

  describe 'PATCH #update' do
    let!(:snippet) { FactoryBot.create(:outgoing_message_snippet) }

    before do
      patch :update, params: params
    end

    context 'on a successful update' do
      let(:params) do
        { id: snippet.id, outgoing_message_snippet: { body: 'New body' } }
      end

      it 'assigns the snippet' do
        expect(assigns[:snippet]).to eq(snippet)
      end

      it 'updates the snippet' do
        expect(snippet.reload.body).to eq('New body')
      end

      it 'sets a notice' do
        expect(flash[:notice]).to eq('Snippet successfully updated.')
      end

      it 'redirects to the snippets index' do
        expect(response).to redirect_to(admin_snippets_path)
      end
    end

    context 'on an unsuccessful update' do
      let(:params) do
        { id: snippet.id, outgoing_message_snippet: { body: '' } }
      end

      it 'assigns the snippet' do
        expect(assigns[:snippet]).to eq(snippet)
      end

      it 'does not update the snippet' do
        expect(snippet.reload.body).not_to be_blank
      end

      it 'assigns a page title' do
        expect(assigns[:title]).to eq('Edit snippet')
      end

      it 'renders the form again' do
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:snippet) { FactoryBot.create(:outgoing_message_snippet) }

    it 'destroys the snippet' do
      allow(OutgoingMessage::Snippet).to receive(:find).and_return(snippet)
      expect(snippet).to receive(:destroy)
      delete :destroy, params: { id: snippet.id }
    end

    it 'sets a notice' do
      delete :destroy, params: { id: snippet.id }
      expect(flash[:notice]).to eq('Snippet successfully destroyed.')
    end

    it 'redirects to the snippets index' do
      delete :destroy, params: { id: snippet.id }
      expect(response).to redirect_to(admin_snippets_path)
    end
  end
end
