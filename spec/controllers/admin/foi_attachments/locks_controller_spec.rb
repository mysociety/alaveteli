require 'spec_helper'

RSpec.describe Admin::FoiAttachments::LocksController do
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

  before { sign_in(admin_user) }

  let(:info_request) { FactoryBot.create(:info_request, :with_plain_incoming) }
  let(:incoming_message) { info_request.incoming_messages.first }
  let!(:attachment) { incoming_message.foi_attachments.first }

  describe 'POST #create' do
    let(:params) { { foi_attachment_id: attachment.id, reason: 'Locking' } }

    context 'on a successful lock' do
      it 'assigns the attachment' do
        post :create, params: params
        expect(assigns[:foi_attachment]).to eq(attachment)
      end

      it 'locks the attachment' do
        post :create, params: params
        expect(attachment.reload).to be_locked
      end

      it 'expires the attachment' do
        expect_any_instance_of(FoiAttachment).to receive(:expire)
        post :create, params: params
      end

      it 'redirects to the attachment edit page' do
        post :create, params: params
        expect(response).to redirect_to(
          edit_admin_foi_attachment_path(attachment)
        )
      end

      it 'logs an edit_attachment event on the info_request' do
        allow(@controller).to receive(:admin_current_user).
          and_return('Admin user')

        post :create, params: params

        info_request.reload
        last_event = info_request.info_request_events.last
        expect(last_event.event_type).to eq('edit_attachment')
        expect(last_event.params).to include(
          editor: 'Admin user',
          reason: 'Locking',
          attachment_id: attachment.id,
          old_locked: false,
          locked: true
        )
      end
    end

    context 'when attachment is locked but not yet masked' do
      before do
        allow_any_instance_of(FoiAttachment).to receive(:masked?).
          and_return(false)
      end

      it 'sets a notice about waiting for masking' do
        post :create, params: params
        expect(flash[:notice]).to eq(<<~TXT.squish)
          Attachment locked. Please wait for masking to complete before adding
          additional censor rules.
        TXT
      end
    end

    context 'when attachment is already masked' do
      before do
        allow_any_instance_of(FoiAttachment).to receive(:masked?).
          and_return(true)
      end

      it 'sets a standard success notice' do
        post :create, params: params
        expect(flash[:notice]).to eq('Attachment locked.')
      end
    end

    context 'on an unsuccessful lock' do
      before do
        allow_any_instance_of(FoiAttachment).to receive(:lock!).
          and_raise(ActiveRecord::RecordInvalid)
      end

      it 'raises an exception' do
        expect { post :create, params: params }.
          to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'if the request is embargoed', feature: :alaveteli_pro do
      before { info_request.create_embargo }

      context 'as non-pro admin' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            post :create, params: params
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'as pro admin' do
        before { sign_in(pro_admin_user) }

        it 'locks the attachment' do
          post :create, params: params
          expect(attachment.reload).to be_locked
        end

        it 'redirects to the attachment edit page' do
          post :create, params: params
          expect(response).to redirect_to(
            edit_admin_foi_attachment_path(attachment)
          )
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:params) { { foi_attachment_id: attachment.id, reason: 'Unlocking' } }

    before { attachment.update(locked: true) }

    context 'on a successful unlock' do
      it 'assigns the attachment' do
        delete :destroy, params: params
        expect(assigns[:foi_attachment]).to eq(attachment)
      end

      it 'unlocks the attachment' do
        delete :destroy, params: params
        expect(attachment.reload).not_to be_locked
      end

      it 'expires the attachment' do
        expect_any_instance_of(FoiAttachment).to receive(:expire)
        delete :destroy, params: params
      end

      it 'sets a success notice' do
        delete :destroy, params: params
        expect(flash[:notice]).to eq('Attachment unlocked.')
      end

      it 'redirects to the attachment edit page' do
        delete :destroy, params: params
        expect(response).to redirect_to(
          edit_admin_foi_attachment_path(attachment)
        )
      end

      it 'logs an edit_attachment event on the info_request' do
        allow(@controller).to receive(:admin_current_user).
          and_return('Admin user')

        delete :destroy, params: params

        info_request.reload
        last_event = info_request.info_request_events.last
        expect(last_event.event_type).to eq('edit_attachment')
        expect(last_event.params).to include(
          editor: 'Admin user',
          reason: 'Unlocking',
          attachment_id: attachment.id,
          old_locked: true,
          locked: false
        )
      end
    end

    context 'on an unsuccessful unlock' do
      before do
        allow(FoiAttachment).to receive(:find).and_return(attachment)
        allow(attachment).to receive(:unlock!).and_return(false)
        attachment.errors.add(:base, 'Cannot unlock')
      end

      it 'assigns the attachment' do
        delete :destroy, params: params
        expect(assigns[:foi_attachment]).to eq(attachment)
      end

      it 'sets an error flash' do
        delete :destroy, params: params
        expect(flash[:error]).to eq('Cannot unlock')
      end

      it 'redirects to the attachment edit page' do
        post :create, params: params
        expect(response).to redirect_to(
          edit_admin_foi_attachment_path(attachment)
        )
      end
    end

    context 'if the request is embargoed', feature: :alaveteli_pro do
      before { info_request.create_embargo }

      context 'as non-pro admin' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            delete :destroy, params: params
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'as pro admin' do
        before { sign_in(pro_admin_user) }

        it 'unlocks the attachment' do
          delete :destroy, params: params
          expect(attachment.reload).not_to be_locked
        end

        it 'redirects to the attachment edit page' do
          delete :destroy, params: params
          expect(response).to redirect_to(
            edit_admin_foi_attachment_path(attachment)
          )
        end
      end
    end
  end
end
