require 'spec_helper'

RSpec.describe Admin::FoiAttachments::MasksController do
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

  before { sign_in(admin_user) }

  let(:info_request) { FactoryBot.create(:info_request, :with_plain_incoming) }
  let(:incoming_message) { info_request.incoming_messages.first }
  let!(:attachment) { incoming_message.foi_attachments.first }

  describe 'POST #create' do
    let(:params) { { foi_attachment_id: attachment.id } }

    context 'on a successful mask' do
      it 'assigns the attachment' do
        post :create, params: params
        expect(assigns[:foi_attachment]).to eq(attachment)
      end

      it 'queues the masking job' do
        expect { post :create, params: params }.
          to have_enqueued_job(FoiAttachmentMaskJob).with(attachment)
      end

      it 'sets a success notice' do
        post :create, params: params
        expect(flash[:notice]).to eq('Masking queued.')
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
            post :create, params: params
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'as pro admin' do
        before { sign_in(pro_admin_user) }

        it 'queues the masking job' do
          expect_any_instance_of(FoiAttachment).to receive(:mask_later)
          post :create, params: params
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
end
