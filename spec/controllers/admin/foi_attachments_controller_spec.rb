require 'spec_helper'

RSpec.describe Admin::FoiAttachmentsController do
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

  before(:each) do
    sign_in(admin_user)
  end

  let(:info_request) { FactoryBot.create(:info_request, :with_plain_incoming) }
  let(:incoming_message) { info_request.incoming_messages.first }
  let!(:attachment) { incoming_message.foi_attachments.first }

  describe 'GET edit' do
    it 'returns a successful response' do
      get :edit, params: { id: attachment.id }
      expect(response).to be_successful
    end

    it 'assigns the attachment' do
      get :edit, params: { id: attachment.id }
      expect(assigns[:foi_attachment]).to eq(attachment)
    end

    it 'renders the correct template' do
      get :edit, params: { id: attachment.id }
      expect(response).to render_template(:edit)
    end

    context 'if the request is embargoed', feature: :alaveteli_pro do
      before { info_request.create_embargo }

      context 'as non-pro admin' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            get :edit, params: { id: attachment.id }
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'as pro admin' do
        before { sign_in(pro_admin_user) }

        it 'renders the edit action' do
          get :edit, params: { id: attachment.id }
          expect(response).to render_template(:edit)
        end
      end
    end
  end
end
