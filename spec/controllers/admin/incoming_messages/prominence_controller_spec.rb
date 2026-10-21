require 'spec_helper'

RSpec.describe Admin::IncomingMessages::ProminenceController do
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

  before { sign_in(admin_user) }

  let(:info_request) { FactoryBot.create(:info_request, :with_plain_incoming) }
  let(:incoming_message) { info_request.incoming_messages.first }

  describe 'PATCH #update' do
    let(:params) do
      {
        incoming_message_id: incoming_message.id,
        incoming_message: {
          prominence: 'hidden',
          prominence_reason: 'Contains personal information'
        }
      }
    end

    context 'on a successful update' do
      it 'assigns the message' do
        patch :update, params: params
        expect(assigns[:incoming_message]).to eq(incoming_message)
      end

      it 'updates the prominence' do
        patch :update, params: params
        expect(incoming_message.reload.prominence).to eq('hidden')
      end

      it 'updates the prominence_reason' do
        patch :update, params: params
        expect(incoming_message.reload.prominence_reason).
          to eq('Contains personal information')
      end

      it 'expires the incoming message' do
        expect_any_instance_of(IncomingMessage).to receive(:expire)
        patch :update, params: params
      end

      it 'sets a success notice' do
        patch :update, params: params
        expect(flash[:notice]).to eq('Prominence updated.')
      end

      it 'redirects to the message show page' do
        patch :update, params: params
        expect(response).to redirect_to(
          admin_incoming_message_path(incoming_message)
        )
      end

      it 'logs an edit_incoming event on the info_request' do
        allow(@controller).to receive(:admin_current_user).
          and_return('Admin user')

        patch :update, params: params

        info_request.reload
        last_event = info_request.info_request_events.last
        expect(last_event.event_type).to eq('edit_incoming')
        expect(last_event.params).to include(
          editor: 'Admin user',
          incoming_message: { gid: incoming_message.to_global_id.to_s },
          old_prominence: 'normal',
          prominence: 'hidden',
          old_prominence_reason: nil,
          prominence_reason: 'Contains personal information'
        )
      end
    end

    context 'on an unsuccessful update' do
      let(:params) do
        {
          incoming_message_id: incoming_message.id,
          incoming_message: {
            prominence: 'invalid_prominence',
            prominence_reason: 'Contains personal information'
          }
        }
      end

      it 'assigns the message' do
        patch :update, params: params
        expect(assigns[:incoming_message]).to eq(incoming_message)
      end

      it 'does not expire the message' do
        expect(incoming_message).not_to receive(:expire)
        patch :update, params: params
      end

      it 'sets an error flash' do
        patch :update, params: params
        expect(flash[:error]).to eq('Prominence is not included in the list')
      end

      it 'redirects to the message show page' do
        patch :update, params: params
        expect(response).to redirect_to(
          admin_incoming_message_path(incoming_message)
        )
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

        it 'updates the prominence' do
          patch :update, params: params
          expect(incoming_message.reload.prominence).to eq('hidden')
        end

        it 'redirects to the message show page' do
          patch :update, params: params
          expect(response).to redirect_to(
            admin_incoming_message_path(incoming_message)
          )
        end
      end
    end
  end
end
