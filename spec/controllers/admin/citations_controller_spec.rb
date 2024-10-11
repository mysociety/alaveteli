require 'spec_helper'

RSpec.describe Admin::CitationsController do
  before(:each) { basic_auth_login(@request) }

  describe 'GET index' do
    before { FactoryBot.create_list(:citation, 3) }
    before { get :index }

    it 'returns a successful response' do
      expect(response).to be_successful
    end

    it 'assigns the citations' do
      expect(assigns[:citations]).to all(be_a(Citation))
    end

    it 'assigns the query' do
      get :index, params: { query: 'hello' }
      expect(assigns[:query]).to eq('hello')
    end

    it 'filters citations by the search query' do
      net = FactoryBot.create(:citation, source_url: 'https://example.net/a')
      org = FactoryBot.create(:citation, source_url: 'https://example.org/b')
      get :index, params: { query: 'example.net' }
      expect(assigns[:citations]).to include(net)
      expect(assigns[:citations]).not_to include(org)
    end

    it 'renders the correct template' do
      expect(response).to render_template(:index)
    end
  end

  describe 'GET edit' do
    let(:citation) { FactoryBot.create(:citation) }
    before { get :edit, params: { id: citation.id } }

    it 'returns a successful response' do
      expect(response).to be_successful
    end

    it 'assigns the citation' do
      expect(assigns[:citation]).to eq(citation)
    end

    it 'renders the correct template' do
      expect(response).to render_template(:edit)
    end
  end

  describe 'PUT update' do
    let(:citation) { FactoryBot.create(:citation) }
    let(:valid_attributes) { { title: 'Updated Title' } }

    context 'with valid params' do
      before do
        put :update, params: { id: citation.id, citation: valid_attributes }
      end

      it 'updates the citation' do
        citation.reload
        expect(citation.title).to eq('Updated Title')
      end

      it 'redirects to the citation' do
        expect(response).to redirect_to(admin_citations_url)
      end
    end

    context 'with invalid params' do
      before do
        put :update, params: { id: citation.id, citation: { source_url: '' } }
      end

      it 'does not update the citation' do
        citation.reload
        expect(citation.source_url).not_to eq('')
      end

      it 're-renders the edit template' do
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE destroy' do
    let!(:citation) { FactoryBot.create(:citation) }

    it 'destroys the requested citation' do
      expect {
        delete :destroy, params: { id: citation.id }
      }.to change(Citation, :count).by(-1)
    end

    it 'redirects to the citations list' do
      delete :destroy, params: { id: citation.id }
      expect(response).to redirect_to(admin_citations_url)
    end
  end
end
