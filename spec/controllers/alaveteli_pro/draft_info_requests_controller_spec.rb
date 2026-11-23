require 'spec_helper'

RSpec.describe AlaveteliPro::DraftInfoRequestsController, feature: :alaveteli_pro do
  let(:pro_user) { FactoryBot.create(:pro_user) }
  let(:public_body) { FactoryBot.create(:public_body) }
  let(:title) { 'Does the pro request form work?' }

  let(:params) do
    {
      info_request: { title: title, public_body_id: public_body.id },
      outgoing_message: { body: 'A very short request.' },
      embargo: { embargo_duration: '3_months' },
      preview: true
    }
  end

  before { sign_in pro_user }

  describe 'POST #create' do
    it 'redirects to the preview' do
      post :create, params: params

      draft = pro_user.draft_info_requests.last
      expect(response).to redirect_to(
        preview_new_alaveteli_pro_info_request_path(draft_id: draft.id)
      )
    end

    context 'when the draft is not valid' do
      render_views

      let(:title) { 'a' * 201 }

      it 'renders the form with the errors and the text' do
        post :create, params: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template('alaveteli_pro/info_requests/new')
        expect(response.body).to include('Please keep the summary short')
        expect(response.body).to include(title)
        expect(response.body).to include('A very short request.')
      end
    end
  end

  describe 'PUT #update' do
    let(:draft) { FactoryBot.create(:draft_info_request, user: pro_user) }

    it 'redirects to the preview' do
      put :update, params: params.merge(id: draft.id)

      expect(response).to redirect_to(
        preview_new_alaveteli_pro_info_request_path(draft_id: draft.id)
      )
    end

    context 'when the draft is not valid' do
      render_views

      let(:title) { 'a' * 201 }

      it 'renders the form with the errors and the edits' do
        put :update, params: params.merge(id: draft.id)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template('alaveteli_pro/info_requests/new')
        expect(response.body).to include('Please keep the summary short')
        expect(response.body).to include(title)
      end
    end
  end
end
