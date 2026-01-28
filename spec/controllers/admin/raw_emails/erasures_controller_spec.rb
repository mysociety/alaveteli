require 'spec_helper'

RSpec.describe Admin::RawEmails::ErasuresController do
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:incoming_message) { FactoryBot.create(:incoming_message) }
  let(:raw_email) { incoming_message.raw_email }

  before { sign_in(admin_user) }

  describe 'POST #create' do
    let(:params) do
      {
        raw_email_id: raw_email.id,
        raw_email: { erasure_reason: 'GDPR request' }
      }
    end

    context 'when erasure is successful' do
      before do
        allow(@controller).
          to receive(:admin_current_user).and_return(admin_user)
      end

      it 'calls erase on the raw_email' do
        expect_any_instance_of(RawEmail).to receive(:erase).with(
          editor: admin_user,
          reason: 'GDPR request'
        ).and_return(true)

        post :create, params: params
      end

      it 'redirects to the raw_email' do
        post :create, params: params
        expect(response).to redirect_to(admin_raw_email_path(raw_email))
      end

      it 'sets a success notice' do
        post :create, params: params
        expect(flash[:notice]).to match(/RawEmail has been erased/)
      end

      it 'erases the raw_email data' do
        expect { post :create, params: params }.
          to change { raw_email.reload.erased? }.from(false).to(true)
      end

      def last_event
        raw_email.
          info_request.
          info_request_events.
          where(event_type: 'erase_raw_email').
          last
      end

      it 'logs an erase_raw_email event' do
        post :create, params: params

        expect(last_event).to be_present
        expect(last_event.params[:editor]).to eq(admin_user)
        expect(last_event.params[:reason]).to eq('GDPR request')
      end
    end

    context 'when erasure fails' do
      before do
        allow_any_instance_of(RawEmail).to receive(:erase).and_return(false)
      end

      it 'redirects to the raw_email' do
        post :create, params: params
        expect(response).to redirect_to(admin_raw_email_path(raw_email))
      end

      it 'sets an error' do
        post :create, params: params
        expect(flash[:error]).to match(/Could not erase this RawEmail/)
      end

      it 'does not erase the raw_email data' do
        expect { post :create, params: params }.
          not_to change { raw_email.reload.erased? }
      end
    end

    context 'when raw_email is already erased' do
      before do
        raw_email.erase(editor: admin_user, reason: 'Already erased')
      end

      it 'returns an error' do
        allow_any_instance_of(RawEmail).
          to receive(:erase).and_raise(RawEmail::AlreadyErasedError)

        post :create, params: params

        expect(response).to redirect_to(admin_raw_email_path(raw_email))
        expect(flash[:error]).to match(/already been erased/)
      end
    end

    context 'when there are unmasked attachments' do
      before do
        raw_email.erase(editor: admin_user, reason: 'Unmasked')
      end

      it 'returns an error' do
        allow_any_instance_of(RawEmail).
          to receive(:erase).and_raise(RawEmail::UnmaskedAttachmentsError)

        post :create, params: params

        expect(response).to redirect_to(admin_raw_email_path(raw_email))
        expect(flash[:error]).to match(/Ensure all attachments are masked/)
      end
    end

    context 'without an erasure_reason' do
      let(:params) do
        {
          raw_email_id: raw_email.id,
          raw_email: { erasure_reason: '' }
        }
      end

      it 'raises ParameterMissing error' do
        expect {
          post :create, params: params
        }.to raise_error(ActionController::ParameterMissing, /erasure_reason/)
      end
    end

    context 'with missing raw_email parameter' do
      it 'raises ParameterMissing error' do
        expect {
          post :create, params: { raw_email_id: raw_email.id }
        }.to raise_error(ActionController::ParameterMissing, /raw_email/)
      end
    end

    context 'with invalid raw_email id' do
      let(:invalid_id) { RawEmail.maximum(:id) + 999 }

      it 'raises RecordNotFound' do
        expect {
          post :create,
               params: {
                 raw_email_id: invalid_id,
                 raw_email: { erasure_reason: 'test' }
               }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
