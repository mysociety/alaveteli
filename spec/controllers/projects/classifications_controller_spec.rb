require 'spec_helper'

spec_meta = {
  type: :controller,
  feature: :projects
}

RSpec.describe Projects::ClassificationsController, spec_meta do
  shared_context 'project can be found' do
    let(:project) { FactoryBot.create(:project) }

    before do
      allow(Project).to receive(:find).with(project.id.to_s).and_return(project)
    end
  end

  shared_context 'request can be found' do
    include_context 'project can be found'

    let(:info_request) { FactoryBot.create(:info_request, user: user) }

    before do
      info_requests = double(:info_requests_collection)
      allow(project).to receive(:info_requests).and_return(info_requests)
      allow(info_requests).to receive(:find_by!).
        with(url_title: info_request.url_title).and_return(info_request)
    end
  end

  describe 'POST #create' do
    let(:user) { FactoryBot.create(:pro_user) }
    let(:ability) { Object.new.extend(CanCan::Ability) }

    before do
      session[:user_id] = user.id
      allow(controller).to receive(:current_user).and_return(user)

      allow(controller).to receive(:current_ability).and_return(ability)
    end

    context 'project to be classified can not be found' do
      it'raises a ActiveRecord::RecordNotFound error' do
        expect {
          post :create, params: { project_id: 'invalid' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'request to be classified can not be found' do
      include_context 'project can be found'

      it'raises a ActiveRecord::RecordNotFound error' do
        expect {
          post :create, params: { project_id: project.id, url_title: 'invalid' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    shared_context 'request to be classified can be found' do
      include_context 'request can be found'

      def post_status(status, message: nil)
        classification = { described_state: status }
        classification[:message] = message if message

        post :create, params: {
          classification: classification,
          project_id: project.id,
          url_title: info_request.url_title
        }
      end
    end

    context 'user is not allowed to update the request' do
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

      it 'create status_update log' do
        post_status('successful')

        event = assigns(:status_update_event)
        expect(event).to be_a InfoRequestEvent
        expect(event.event_type).to eq 'status_update'
        expect(event.params[:described_state]).to eq 'successful'
        expect(event.params[:old_described_state]).to eq 'waiting_response'
        expect(event.params[:user_id]).to eq user.id
      end

      it 'call set_described_state on the request' do
        expect(info_request).to receive(:set_described_state)
        post_status('successful')
      end

      it 'redirect back to the project' do
        post_status('successful')
        expect(response).to redirect_to(project_path(project))
      end
    end

    context 'user sets the request as error_message without a message' do
      include_context 'user can classify request'

      it 'redirect the add message action' do
        post_status('error_message')
        expect(response).to redirect_to(
          message_project_classification_path(
            project_id: project.id,
            url_title: info_request.url_title,
            described_state: 'error_message'
          )
        )
      end
    end

    context 'user sets the request as error_message with a message' do
      include_context 'user can classify request'

      it 'create status_update log' do
        post_status('error_message', message: 'A message')

        event = assigns(:status_update_event)
        expect(event).to be_a InfoRequestEvent
        expect(event.event_type).to eq 'status_update'
        expect(event.params[:described_state]).to eq 'error_message'
        expect(event.params[:old_described_state]).to eq 'waiting_response'
        expect(event.params[:message]).to eq 'A message'
        expect(event.params[:user_id]).to eq info_request.user_id
      end

      it 'call set_described_state on the request' do
        expect(info_request).to receive(:set_described_state)
        post_status('error_message', message: 'A message')
      end

      it 'redirect back to the project' do
        post_status('error_message', message: 'A message')
        expect(response).to redirect_to(project_path(project))
      end
    end

    context 'user sets the request as requires_admin without a message' do
      include_context 'user can classify request'

      it 'redirect the add message action' do
        post_status('requires_admin')
        expect(response).to redirect_to(
          message_project_classification_path(
            project_id: project.id,
            url_title: info_request.url_title,
            described_state: 'requires_admin'
          )
        )
      end
    end

    context 'user sets the request as requires_admin with a message' do
      include_context 'user can classify request'

      it 'create status_update log' do
        post_status('requires_admin', message: 'A message')

        event = assigns(:status_update_event)
        expect(event).to be_a InfoRequestEvent
        expect(event.event_type).to eq 'status_update'
        expect(event.params[:described_state]).to eq 'requires_admin'
        expect(event.params[:old_described_state]).to eq 'waiting_response'
        expect(event.params[:message]).to eq 'A message'
        expect(event.params[:user_id]).to eq info_request.user_id
      end

      it 'call set_described_state on the request' do
        expect(info_request).to receive(:set_described_state)
        post_status('requires_admin', message: 'A message')
      end

      it 'redirect back to the project' do
        post_status('requires_admin', message: 'A message')
        expect(response).to redirect_to(project_path(project))
      end
    end
  end

  describe '#message' do
    include_examples 'request can be found'
    include_examples 'adding classification message action'

    def run_action
      get :message, params: {
        project_id: project.id,
        url_title: info_request.url_title,
        described_state: 'error_message'
      }
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:info_request) { FactoryBot.create(:info_request, user: user) }
  end
end
