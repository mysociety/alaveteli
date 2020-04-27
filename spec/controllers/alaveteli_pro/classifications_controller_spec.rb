require 'spec_helper'

RSpec.describe AlaveteliPro::ClassificationsController, type: :controller do
  describe '#create' do
    let(:user) { FactoryBot.create(:pro_user) }
    let(:ability) { Object.new.extend(CanCan::Ability) }

    before do
      session[:user_id] = user.id
      allow(controller).to receive(:current_user).and_return(user)

      allow(controller).to receive(:current_ability).and_return(ability)
    end

    context 'request to be classified can not be found' do
      it'raises a ActiveRecord::RecordNotFound error' do
        expect {
          post :create, params: { url_title: 'invalid' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    shared_context 'request to be classified can be found' do
      let(:info_request) { FactoryBot.create(:info_request, user: user) }

      before do
        allow(InfoRequest).to receive(:find_by!).with(url_title: 'url_title').
          and_return(info_request)
      end

      def post_status(status, message: nil)
        classification = { described_state: status }
        classification[:message] = message if message

        post :create, params: {
          classification: classification,
          url_title: 'url_title'
        }
      end
    end

    context 'user is not allow to update the request' do
      include_context 'request to be classified can be found'

      before { ability.cannot :update_request_state, info_request }

      it 'raises a CanCan::AccessDenied error' do
        expect {
          post_status('successful')
        }.to raise_error(CanCan::AccessDenied)
      end
    end

    shared_context 'user can classify request' do
      include_context 'request to be classified can be found'
      before { ability.can :update_request_state, info_request }
    end

    context 'user is allowed to update the request' do
      include_context 'user can classify request'

      it 'should create status_update log' do
        post_status('successful')

        event = assigns(:status_update_event)
        expect(event).to be_a InfoRequestEvent
        expect(event.event_type).to eq 'status_update'
        expect(event.params[:described_state]).to eq 'successful'
        expect(event.params[:old_described_state]).to eq 'waiting_response'
        expect(event.params[:user_id]).to eq info_request.user_id
      end

      it 'should call set_described_state on the request' do
        expect(info_request).to receive(:set_described_state)
        post_status('successful')
      end

      it 'should redirect back to the request' do
        post_status('successful')
        expect(response).to redirect_to(
          show_alaveteli_pro_request_path(url_title: info_request.url_title)
        )
      end
    end

    context 'user sets the request as error_message without a message' do
      include_context 'user can classify request'

      it 'should redirect the add message action' do
        post_status('error_message')
        expect(response).to redirect_to(
          message_alaveteli_pro_classification_path(
            url_title: info_request.url_title,
            described_state: 'error_message'
          )
        )
      end
    end

    context 'user sets the request as error_message with a message' do
      include_context 'user can classify request'

      it 'should create status_update log' do
        post_status('error_message', message: 'A message')

        event = assigns(:status_update_event)
        expect(event).to be_a InfoRequestEvent
        expect(event.event_type).to eq 'status_update'
        expect(event.params[:described_state]).to eq 'error_message'
        expect(event.params[:old_described_state]).to eq 'waiting_response'
        expect(event.params[:message]).to eq 'A message'
        expect(event.params[:user_id]).to eq info_request.user_id
      end

      it 'should call set_described_state on the request' do
        expect(info_request).to receive(:set_described_state)
        post_status('error_message', message: 'A message')
      end

      it 'should redirect back to the request' do
        post_status('error_message', message: 'A message')
        expect(response).to redirect_to(
          show_alaveteli_pro_request_path(url_title: info_request.url_title)
        )
      end
    end

    context 'user sets the request as requires_admin without a message' do
      include_context 'user can classify request'

      it 'should redirect the add message action' do
        post_status('requires_admin')
        expect(response).to redirect_to(
          message_alaveteli_pro_classification_path(
            url_title: info_request.url_title,
            described_state: 'requires_admin'
          )
        )
      end
    end

    context 'user sets the request as requires_admin without a message' do
      include_context 'user can classify request'

      it 'should create status_update log' do
        post_status('requires_admin', message: 'A message')

        event = assigns(:status_update_event)
        expect(event).to be_a InfoRequestEvent
        expect(event.event_type).to eq 'status_update'
        expect(event.params[:described_state]).to eq 'requires_admin'
        expect(event.params[:old_described_state]).to eq 'waiting_response'
        expect(event.params[:message]).to eq 'A message'
        expect(event.params[:user_id]).to eq info_request.user_id
      end

      it 'should call set_described_state on the request' do
        expect(info_request).to receive(:set_described_state)
        post_status('requires_admin', message: 'A message')
      end

      it 'should redirect back to the request' do
        post_status('requires_admin', message: 'A message')
        expect(response).to redirect_to(
          show_alaveteli_pro_request_path(url_title: info_request.url_title)
        )
      end
    end
  end

  describe '#message' do
    include_examples 'adding classification message action'

    let(:user) { FactoryBot.create(:pro_user) }
    let(:info_request) { FactoryBot.create(:info_request, user: user) }
  end
end
