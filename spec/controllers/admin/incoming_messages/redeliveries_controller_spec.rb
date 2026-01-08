require 'spec_helper'

RSpec.describe Admin::IncomingMessages::RedeliveriesController do
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

  before { sign_in(admin_user) }

  describe 'POST #create' do
    let(:previous_info_request) { FactoryBot.build(:info_request) }
    let(:incoming_message) do
      FactoryBot.create(:incoming_message, info_request: previous_info_request)
    end
    let(:destination_info_request) { FactoryBot.create(:info_request) }
    let(:destination_info_request_2) { FactoryBot.create(:info_request) }

    it 'expires the file cache for the previous request' do
      allow(IncomingMessage).to receive(:find).and_return(incoming_message)
      expect(previous_info_request).to receive(:expire)
      post :create, params: {
                         incoming_message_id: incoming_message.id,
                         url_title: destination_info_request.url_title
                       }
    end

    it 'takes no action if no message_id is supplied' do
      post :create, params: {
                         incoming_message_id: incoming_message.id,
                         url_title: ''
                       }
      # It shouldn't delete this message
      assert_equal IncomingMessage.exists?(incoming_message.id), true
      # Should show an error to the user
      assert_equal(
        flash[:error],
        "You must supply at least one request to redeliver the message to."
      )
      expect(response).
        to redirect_to admin_request_url(incoming_message.info_request)
    end

    context 'when redelivering to multiple requests' do
      before do
        destination_params =
          [destination_info_request, destination_info_request_2].
          map(&:id).
          join(', ')

        post :create,
             params: { incoming_message_id: incoming_message.id,
                       url_title: destination_params }
      end

      it 'renders a message' do
        msg = 'Message has been moved to request(s). Showing the last one:'
        expect(flash[:notice]).to eq(msg)
      end

      it 'redirects to the last given destination request' do
        expect(response).
          to redirect_to admin_request_path(destination_info_request_2)
      end
    end

    context 'if the request is embargoed', feature: :alaveteli_pro do
      before do
        incoming_message.info_request.create_embargo
      end

      context 'as non-pro admin' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            post :create, params: {
              incoming_message_id: incoming_message,
              url_title: destination_info_request.url_title
            }
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'as pro admin' do
        before { sign_in(pro_admin_user) }

        it 'redirects to destination request admin' do
          post :create, params: {
            incoming_message_id: incoming_message,
            url_title: destination_info_request.url_title
          }
          expect(response).to redirect_to \
            admin_request_url(destination_info_request)
        end
      end
    end

    context 'when the raw email has been erased' do
      before do
        incoming_message.raw_email.erase(editor: admin_user, reason: 'test')
      end

      it 'raises an error' do
        expect {
          post :create, params: {
            incoming_message_id: incoming_message,
            url_title: destination_info_request.url_title
          }
        }.to raise_error(described_class::NotRedeliverableError)
      end
    end
  end
end
