require 'spec_helper'

RSpec.describe IncomingMessages::UnmaskedController, feature: :unmasked_main_body do
  include_context 'unmasked main body available'

  describe 'GET show' do
    let(:owner) { FactoryBot.create(:user) }
    let(:info_request) { FactoryBot.create(:info_request, user: owner) }

    let!(:incoming_message) do
      receive_incoming_mail(<<~EML, to: info_request.incoming_email)
        From: EMAIL_FROM
        To: EMAIL_TO
        Subject: Basic Email

        Contact me at officer@example.com
      EML
      info_request.incoming_messages.last
    end

    context 'as the request owner' do
      before { sign_in owner }

      it 'assigns the incoming message' do
        get :show, params: { incoming_message_id: incoming_message.id }
        expect(assigns[:incoming_message]).to eq(incoming_message)
      end

      it 'assigns the unmasked body' do
        get :show, params: { incoming_message_id: incoming_message.id }
        expect(assigns[:body]).to include('officer@example.com')
      end

      it 'prevents the response being cached' do
        get :show, params: { incoming_message_id: incoming_message.id }
        expect(response.headers['Cache-Control']).to include('no-store')
      end

      it 'renders the show template' do
        get :show, params: { incoming_message_id: incoming_message.id }
        expect(response).to render_template('show')
      end

      it 'renders only the unmasked body for XHR requests' do
        get :show, xhr: true,
                   params: { incoming_message_id: incoming_message.id }
        expect(response).to render_template(partial: '_unmasked_body')
        expect(response).not_to render_template('show')
      end

      context 'when the feature is disabled', feature: { unmasked_main_body: false } do
        it 'raises a CanCan::AccessDenied error' do
          expect {
            get :show, params: { incoming_message_id: incoming_message.id }
          }.to raise_error(CanCan::AccessDenied)
        end
      end

      context 'when censor rules apply to the request' do
        before do
          FactoryBot.create(:info_request_censor_rule, censorable: info_request)
        end

        it 'raises a CanCan::AccessDenied error' do
          expect {
            get :show, params: { incoming_message_id: incoming_message.id }
          }.to raise_error(CanCan::AccessDenied)
        end
      end

      context 'when the message is hidden' do
        before { incoming_message.update!(prominence: 'hidden') }

        it 'raises a CanCan::AccessDenied error' do
          expect {
            get :show, params: { incoming_message_id: incoming_message.id }
          }.to raise_error(CanCan::AccessDenied)
        end
      end
    end

    context 'as another user' do
      before { sign_in FactoryBot.create(:user) }

      it 'raises a CanCan::AccessDenied error' do
        expect {
          get :show, params: { incoming_message_id: incoming_message.id }
        }.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'as an admin' do
      before { sign_in FactoryBot.create(:admin_user) }

      it 'assigns the unmasked body' do
        get :show, params: { incoming_message_id: incoming_message.id }
        expect(assigns[:body]).to include('officer@example.com')
      end
    end

    context 'when not signed in' do
      it 'raises a CanCan::AccessDenied error' do
        expect {
          get :show, params: { incoming_message_id: incoming_message.id }
        }.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
