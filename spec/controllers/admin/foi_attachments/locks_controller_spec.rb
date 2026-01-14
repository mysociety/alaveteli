require 'spec_helper'

RSpec.describe Admin::FoiAttachments::LocksController do
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

  before { sign_in(admin_user) }

  let(:info_request) { FactoryBot.create(:info_request, :with_plain_incoming) }
  let(:incoming_message) { info_request.incoming_messages.first }
  let!(:attachment) { incoming_message.foi_attachments.first }

  describe 'POST #create' do
    let(:params) do
      {
        foi_attachment_id: attachment.id,
        foi_attachment: { lock_reason: 'Locking for GDPR compliance' }
      }
    end

    context 'when locking succeeds' do
      it 'locks the attachment' do
        expect {
          post :create, params: params
        }.to change { attachment.reload.locked? }.from(false).to(true)
      end

      it 'redirects to the attachment edit page' do
        post :create, params: params
        expect(response).to redirect_to(edit_admin_foi_attachment_path(attachment))
      end

      context 'when attachment is not yet masked' do
        it 'sets a notice about waiting for masking' do
          post :create, params: params
          expect(flash[:notice]).to eq(<<~TXT.squish)
            Attachment successfully locked. Please wait for masking to
            complete before adding additional censor rules.
          TXT
        end
      end

      context 'when attachment is already masked' do
        before do
          attachment.update_columns(masked_at: 1.hour.ago)
          attachment.file.attach(
            io: StringIO.new('test'),
            filename: 'test.txt',
            content_type: 'text/plain'
          )
        end

        it 'sets a simple success notice' do
          post :create, params: params
          expect(flash[:notice]).to eq('Attachment successfully locked.')
        end
      end
    end

    context 'when locking fails' do
      before do
        allow(FoiAttachment).to receive(:find).and_return(attachment)
        allow(attachment).to receive(:lock).and_return(false)
        attachment.errors.add(:base, 'Cannot lock attachment')
      end

      it 'sets a flash error' do
        post :create, params: params
        expect(flash[:error]).to eq('Cannot lock attachment')
      end

      it 'redirects to the attachment edit page' do
        post :create, params: params
        expect(response).to redirect_to(edit_admin_foi_attachment_path(attachment))
      end
    end

    context 'when lock_reason is missing' do
      let(:params) do
        { foi_attachment_id: attachment.id, foi_attachment: { lock_reason: '' } }
      end

      it 'raises ActionController::ParameterMissing' do
        expect {
          post :create, params: params
        }.to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'when foi_attachment params are missing entirely' do
      let(:params) { { foi_attachment_id: attachment.id } }

      it 'raises ActionController::ParameterMissing' do
        expect {
          post :create, params: params
        }.to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'if the request is embargoed', feature: :alaveteli_pro do
      before { info_request.create_embargo }

      context 'as non-pro admin' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            post :create, params: params
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'as pro admin' do
        before { sign_in(pro_admin_user) }

        it 'locks the attachment' do
          expect {
            post :create, params: params
          }.to change { attachment.reload.locked? }.from(false).to(true)
        end

        it 'redirects to the attachment edit page' do
          post :create, params: params
          expect(response).to redirect_to(edit_admin_foi_attachment_path(attachment))
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:params) do
      {
        foi_attachment_id: attachment.id,
        foi_attachment: { lock_reason: 'Unlocking to apply new censor rules' }
      }
    end

    before do
      attachment.update_columns(locked: true)
    end

    context 'when unlocking succeeds' do
      it 'unlocks the attachment' do
        expect {
          delete :destroy, params: params
        }.to change { attachment.reload.locked? }.from(true).to(false)
      end

      it 'redirects to the attachment edit page' do
        delete :destroy, params: params
        expect(response).to redirect_to(edit_admin_foi_attachment_path(attachment))
      end

      it 'sets a success notice' do
        delete :destroy, params: params
        expect(flash[:notice]).to eq('Attachment unlocked.')
      end
    end

    context 'when unlocking fails' do
      before do
        allow(FoiAttachment).to receive(:find).and_return(attachment)
        allow(attachment).to receive(:unlock).and_return(false)
      end

      it 'sets a flash error' do
        delete :destroy, params: params
        expect(flash[:error]).to eq('This attachment cannot be unlocked.')
      end

      it 'redirects to the attachment edit page' do
        delete :destroy, params: params
        expect(response).to redirect_to(edit_admin_foi_attachment_path(attachment))
      end
    end

    context 'when lock_reason is missing' do
      let(:params) do
        { foi_attachment_id: attachment.id, foi_attachment: { lock_reason: '' } }
      end

      it 'raises ActionController::ParameterMissing' do
        expect {
          delete :destroy, params: params
        }.to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'if the request is embargoed', feature: :alaveteli_pro do
      before { info_request.create_embargo }

      context 'as non-pro admin' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            delete :destroy, params: params
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'as pro admin' do
        before { sign_in(pro_admin_user) }

        it 'unlocks the attachment' do
          expect {
            delete :destroy, params: params
          }.to change { attachment.reload.locked? }.from(true).to(false)
        end

        it 'redirects to the attachment edit page' do
          delete :destroy, params: params
          expect(response).to redirect_to(edit_admin_foi_attachment_path(attachment))
        end
      end
    end
  end
end
