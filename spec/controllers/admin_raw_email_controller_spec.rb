require 'spec_helper'

RSpec.describe AdminRawEmailController do

  describe 'GET show' do

    let(:raw_email) { FactoryBot.create(:incoming_message).raw_email }

    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

    describe 'html version' do
      before { sign_in admin_user }

      it 'renders the show template' do
        get :show, params: { id: raw_email.id }
      end

      context 'when showing a message with a "From" address in the holding pen' do
        let(:raw_email_data) do
          <<-EOF.strip_heredoc
          From: bob@example.uk
          To: #{ invalid_to }
          Subject: Basic Email
          Hello, World
          EOF
        end

        let(:public_body) do
          FactoryBot.create(:public_body, request_email: 'body@example.uk')
        end

        let(:info_request) { info_request = FactoryBot.create(:info_request) }

        let(:invalid_to) do
          info_request.incoming_email.sub(info_request.id.to_s, 'invalid')
        end

        let(:incoming_message) do
          incoming_message = FactoryBot.create(
            :plain_incoming_message,
            info_request: InfoRequest.holding_pen_request
          )
          incoming_message.raw_email.data = raw_email_data
          incoming_message.raw_email.save!
          incoming_message
        end

        let!(:info_request_event) do
          FactoryBot.create(
            :info_request_event,
            event_type: 'response',
            info_request: InfoRequest.holding_pen_request,
            incoming_message: incoming_message,
            params: { rejected_reason: 'Too dull' }
          )
        end

        it 'assigns public bodies that match the "From" domain' do
          get :show, params: { id: incoming_message.raw_email.id }
          expect(assigns[:public_bodies]).to eq [public_body]
        end

        it 'assigns guessed requests based on the hash' do
          get :show, params: { id: incoming_message.raw_email.id }
          idhash = InfoRequest.hash_from_id(info_request.id)
          guess = Guess.new(
            info_request, email: invalid_to, id: nil, idhash: idhash
          )
          expect(assigns[:guessed_info_requests]).to eq([guess])
        end

        it 'assigns guessed requests based on the message subject' do
          other_request =
            FactoryBot.create(:incoming_message, subject: 'Basic Email').
              info_request
          get :show, params: { id: incoming_message.raw_email.id }
          guess = Guess.new(other_request, subject: 'Basic Email')
          expect(assigns[:guessed_info_requests]).to include(guess)
        end

        it 'assigns a reason why the message is in the holding pen' do
          get :show, params: { id: incoming_message.raw_email.id }
          expect(assigns[:rejected_reason]).to eq 'Too dull'
        end

        it 'assigns a default reason if no reason is given' do
          info_request_event.params = {}
          info_request_event.save!
          get :show, params: { id: incoming_message.raw_email.id }
          expect(assigns[:rejected_reason]).to eq 'unknown reason'
        end

      end

    end

    describe 'text version' do
      before { sign_in admin_user }

      it 'sends the email as an RFC-822 attachment' do
        get :show, params: { id: raw_email.id, format: 'eml' }
        expect(response.media_type).to eq('message/rfc822')
        expect(response.body).to eq(raw_email.data)
      end
    end

    context 'if the request is embargoed', feature: :alaveteli_pro do
      before do
        raw_email.incoming_message.info_request.create_embargo
      end

      context 'as non-pro admin' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            get :show, params: { id: raw_email }
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'as pro admin' do
        before { sign_in(pro_admin_user) }

        it 'is successful' do
          get :show, params: { id: raw_email }
          expect(response).to be_successful
        end
      end
    end
  end
end
