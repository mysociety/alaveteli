# spec/controllers/admin/citations_controller_spec.rb
require 'spec_helper'

RSpec.describe Admin::CitationsController, type: :controller do
  let(:admin) { FactoryBot.create(:user, :admin) }

  before do
    sign_in admin
  end

  describe 'GET #index' do
    it 'responds successfully with an HTTP 200 status code' do
      get :index
      expect(response).to be_successful
      expect(response.status).to eq(200)
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template('index')
    end

    it 'loads all citations into @citations' do
      citation1 = FactoryBot.create(:citation)
      citation2 = FactoryBot.create(:citation)
      get :index
      expect(assigns(:citations)).to match_array([citation1, citation2])
    end
  end

  describe 'DELETE #destroy' do
    let!(:citation) { FactoryBot.create(:citation) }

    context 'when deleting a single citation' do
      it 'deletes the citation' do
        expect {
          delete :destroy, params: { id: citation.id }
        }.to change(Citation, :count).by(-1)
      end

      it 'redirects back with a notice' do
        delete :destroy, params: { id: citation.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('Citation deleted successfully.')
      end
    end

    context 'when deleting multiple citations' do
      let!(:citation2) { FactoryBot.create(:citation) }

      it 'deletes the selected citations' do
        expect {
          delete :destroy, params: { citation_ids: [citation.id, citation2.id] }
        }.to change(Citation, :count).by(-2)
      end

      it 'redirects back with a notice' do
        delete :destroy, params: { citation_ids: [citation.id, citation2.id] }
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('Citation(s) deleted successfully.')
      end
    end
  end
end
