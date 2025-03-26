require 'spec_helper'

RSpec.describe Admin::InsightsController, type: :controller, feature: :insights do
  let(:info_request) { FactoryBot.create(:info_request) }
  let(:insight) { FactoryBot.create(:insight, info_request: info_request) }

  describe 'GET #show' do
    it 'renders the show template' do
      get :show, params: { info_request_id: info_request, id: insight }
      expect(response).to render_template(:show)
    end
  end

  describe 'GET #new' do
    it 'assigns a new insight' do
      get :new, params: { info_request_id: info_request }
      expect(assigns(:insight)).to be_a(Insight)
      expect(assigns(:insight)).to be_new_record
    end

    context 'when previous insights exist' do
      let!(:last_insight) do
        FactoryBot.create(
          :insight, model: 'Model', temperature: '0.7',
          prompt_template: 'Template'
        )
      end

      it 'copies model, temperature and prompt_template from last insight' do
        get :new, params: { info_request_id: info_request }
        expect(assigns(:insight).model).to eq(last_insight.model)
        expect(assigns(:insight).temperature).to eq(last_insight.temperature)
        expect(assigns(:insight).prompt_template).
          to eq(last_insight.prompt_template)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        info_request_id: info_request,
        insight: {
          model: 'TestModel', temperature: '0.3',
          prompt_template: 'TestTemplate'
        }
      }
    end

    context 'with valid params' do
      it 'creates a new insight' do
        expect {
          post :create, params: valid_params
        }.to change(Insight, :count).by(1)
      end

      it 'redirects to the created insight' do
        post :create, params: valid_params
        expect(response).to redirect_to(
          admin_info_request_insight_path(info_request, Insight.last)
        )
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          info_request_id: info_request,
          insight: { model: nil, temperature: nil, prompt_template: nil }
        }
      end

      it 'renders the new template' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:insight_to_delete) do
      FactoryBot.create(:insight, info_request: info_request)
    end

    it 'destroys the insight' do
      expect {
        delete :destroy, params: {
          info_request_id: info_request, id: insight_to_delete
        }
      }.to change(Insight, :count).by(-1)
    end

    it 'redirects to the info request page' do
      delete :destroy, params: {
        info_request_id: info_request, id: insight_to_delete
      }
      expect(response).to redirect_to(admin_request_path(info_request))
    end
  end
end
