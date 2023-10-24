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

  describe 'PATCH #update' do
    let(:params) do
      {
        id: attachment.id,
        foi_attachment: {
          prominence: 'hidden',
          prominence_reason: 'This was accidentally published'
        }
      }
    end

    shared_context 'successful update' do
      it 'assigns the attachment' do
        patch :update, params: params
        expect(assigns[:foi_attachment]).to eq(attachment)
      end

      it 'updates the attachment' do
        patch :update, params: params
        expect(attachment.reload.prominence).to eq('hidden')
      end

      it 'sets a notice' do
        patch :update, params: params
        expect(flash[:notice]).to eq('Attachment successfully updated.')
      end

      it 'should log an "edit_attachment" event on the info_request' do
        expect(NotifyCacheJob).to receive(:perform_later).with(attachment)
        allow(@controller).to receive(:admin_current_user).
          and_return("Admin user")

        patch :update, params: params

        info_request.reload
        last_event = info_request.info_request_events.last
        expect(last_event.event_type).to eq('edit_attachment')
        expect(last_event.params).to eq(
          editor: 'Admin user',
          attachment_id: attachment.id,
          old_prominence: 'normal',
          prominence: 'hidden',
          old_prominence_reason: nil,
          prominence_reason: 'This was accidentally published'
        )
      end
    end

    context 'on a successful update of attachment' do
      include_context 'successful update'

      it 'redirects to the incoming message admin' do
        patch :update, params: params
        expect(response).to redirect_to(
          edit_admin_incoming_message_path(incoming_message)
        )
      end
    end

    context 'on an unsuccessful update' do
      before do
        allow(FoiAttachment).to receive(:find).and_return(attachment)
        allow(attachment).to receive(:update).and_return(false)
      end

      it 'assigns the attachment' do
        patch :update, params: params
        expect(assigns[:foi_attachment]).to eq(attachment)
      end

      it 'does not update the attachment' do
        patch :update, params: params
        expect(attachment.reload.prominence).not_to be_blank
      end

      it 'renders the form again' do
        patch :update, params: params
        expect(response).to render_template(:edit)
      end
    end

    context 'if the request is embargoed', feature: :alaveteli_pro do
      before { info_request.create_embargo }

      context 'as non-pro admin' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            patch :update, params: params
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'as pro admin' do
        before { sign_in(pro_admin_user) }

        it 'redirects to the incoming message admin' do
          patch :update, params: params
          expect(response).to redirect_to(
            edit_admin_incoming_message_path(incoming_message)
          )
        end
      end
    end
  end
end
