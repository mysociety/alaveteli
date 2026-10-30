require 'spec_helper'

RSpec.describe Admin::IncomingMessages::ErasuresController do
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }
  let(:info_request) { FactoryBot.create(:info_request_with_incoming) }
  let(:incoming_message) { info_request.incoming_messages.first }

  before do
    sign_in admin_user
    allow(@controller).to receive(:admin_current_user).and_return(admin_user)
  end

  describe 'POST #create' do
    let(:erase_params) do
      {
        incoming_message_id: incoming_message.id,
        editor: admin_user,
        incoming_message: { erasure_reason: 'GDPR request' }
      }
    end

    # FIXME: this test is flaky???
    it 'queues an erase job for the incoming message' do
      expect { post :create, params: erase_params }.
        to have_enqueued_job(IncomingMessage::EraseJob).
        with(incoming_message, editor: admin_user, reason: 'GDPR request')
      # force performing jobs so that uniqueness locks are cleared.
      # Without this, they can remain in redis and break subsequent test runs.
      perform_enqueued_jobs
    end

    it 'redirects to edit page with success message' do
      post :create, params: erase_params

      expect(response).
        to redirect_to(edit_admin_incoming_message_path(incoming_message))
      expect(flash[:notice]).to eq('Incoming message erasure has been queued.')
    end

    it 'raises ParameterMissing if reason is blank' do
      expect {
        post :create, params: {
          incoming_message_id: incoming_message.id,
          editor: admin_user,
          incoming_message: { erasure_reason: '' }
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

    context 'if the request is embargoed', feature: :alaveteli_pro do
      before do
        info_request.create_embargo
      end

      context 'as non-pro admin' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            post :create, params: erase_params
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'as pro admin' do
        before { sign_in(pro_admin_user) }

        it 'redirects to request admin' do
          post :create, params: erase_params
          expect(response).
            to redirect_to edit_admin_incoming_message_path(incoming_message)
        end
      end
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
