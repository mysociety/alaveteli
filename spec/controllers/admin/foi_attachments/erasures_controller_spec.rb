require 'spec_helper'

RSpec.describe Admin::FoiAttachments::ErasuresController do
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:info_request) { FactoryBot.create(:info_request_with_incoming) }
  let(:incoming_message) { info_request.incoming_messages.first }
  let(:foi_attachment) do
    FactoryBot.create(:body_text, incoming_message: incoming_message)
  end

  before do
    sign_in admin_user
    allow(@controller).to receive(:admin_current_user).and_return(admin_user)
  end

  describe 'POST #create' do
    let(:erase_params) do
      {
        foi_attachment_id: foi_attachment.id,
        foi_attachment: { erasure_reason: 'GDPR request' }
      }
    end

    it 'erases the attachment with editor and reason' do
      post :create, params: erase_params

      foi_attachment.reload
      expect(foi_attachment.erased?).to be true

      info_request.reload
      event = info_request.info_request_events.last
      expect(event.event_type).to eq('erase_attachment')
      expect(event.params[:editor]).to eq(admin_user)
      expect(event.params[:reason]).to eq('GDPR request')
    end

    it 'redirects to edit page with success message' do
      post :create, params: erase_params

      expect(response).
        to redirect_to(edit_admin_foi_attachment_path(foi_attachment))
      expect(flash[:notice]).to eq('Attachment successfully erased.')
    end

    it 'shows error message if erasure fails' do
      allow_any_instance_of(FoiAttachment).to receive(:erase).and_return(false)

      post :create, params: erase_params

      expect(response).
        to redirect_to(edit_admin_foi_attachment_path(foi_attachment))
      expect(flash[:error]).
        to eq('Could not erase this attachment. Request technical assistance.')
    end

    it 'raises ParameterMissing if reason is blank' do
      expect {
        post :create, params: {
          foi_attachment_id: foi_attachment.id,
          foi_attachment: { erasure_reason: '' }
        }
      }.to raise_error(ActionController::ParameterMissing)
    end

    it 'requires admin permission' do
      basic_user = FactoryBot.create(:user)
      sign_in basic_user

      expect {
        post :create, params: erase_params
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns 404 if user cannot admin the request' do
      other_admin = FactoryBot.create(:admin_user)
      sign_in other_admin

      allow_any_instance_of(Ability).to receive(:can?).
        with(:admin, info_request).and_return(false)

      expect {
        post :create, params: erase_params
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
