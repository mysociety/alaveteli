require 'spec_helper'

RSpec.describe Admin::CitationsController, type: :controller do
  let(:admin) { FactoryBot.create(:user, :admin) }

  before do
    sign_in admin
  end

  describe 'GET #index' do
    let!(:citation1) { FactoryBot.create(:citation) }
    let!(:citation2) { FactoryBot.create(:citation) }

    before { get :index }

    it 'responds successfully with an HTTP 200 status code' do
      expect(response).to be_successful
      expect(response.status).to eq(200)
    end

    it 'renders the index template' do
      expect(response).to render_template('index')
    end

    it 'loads all citations into @citations' do
      expect(assigns(:citations)).to match_array([citation1, citation2])
    end
  end

  describe 'DELETE #destroy' do
    shared_examples_for 'deletes citations and redirects with notice' do
      it 'deletes the specified citation(s)' do
        expect {
          delete :destroy, params: deletion_params
        }.to change(Citation, :count).by(-citations_count)
      end

      it 'redirects back with a notice' do
        delete :destroy, params: deletion_params
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq(success_message)
      end
    end

    context 'when deleting a single citation' do
      let!(:citation) { FactoryBot.create(:citation) }
      let(:deletion_params) { { id: citation.id } }
      let(:citations_count) { 1 }
      let(:success_message) { 'Citation deleted successfully.' }

      it_behaves_like 'deletes citations and redirects with notice'
    end

    context 'when deleting multiple citations' do
      let!(:citation1) { FactoryBot.create(:citation) }
      let!(:citation2) { FactoryBot.create(:citation) }
      let(:deletion_params) { { citation_ids: [citation1.id, citation2.id] } }
      let(:citations_count) { 2 }
      let(:success_message) { 'Citation(s) deleted successfully.' }

      it_behaves_like 'deletes citations and redirects with notice'
    end
  end
end
