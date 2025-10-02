require 'spec_helper'

require_dependency 'project/queue'

spec_meta = {
  type: :controller,
  feature: :projects
}

RSpec.describe Projects::ClassifiesController, spec_meta do
  before do
    allow(controller).to receive(:site_name).and_return('SITE')
  end

  describe 'GET #show' do
    let(:project) { FactoryBot.create(:project, requests_count: 1) }

    let(:queue) { Project::Queue.classifiable(project, session) }

    let(:ability) { Object.new.extend(CanCan::Ability) }

    before do
      allow(controller).to receive(:current_ability).and_return(ability)
      project.requests << FactoryBot.create(:awaiting_description)
    end

    context 'with a logged in user who can read the project' do
      let(:user) { FactoryBot.create(:user) }

      before do
        sign_in user
        ability.can :read, project
        project.requests << FactoryBot.create(:awaiting_description)
        get :show, params: { project_id: project.id }
      end

      it 'assigns the project' do
        expect(assigns[:project]).to eq(project)
      end

      it 'assigns a queue for the current project and user' do
        expect(assigns[:queue]).to eq(queue)
      end

      it 'assigns an info_request from the queue' do
        expect(queue).to include(assigns[:info_request])
      end

      it 'remembers the current request' do
        current_request_id =
          session['projects'][project.to_param]['classifiable']['current']

        expect(current_request_id).to eq(assigns[:info_request].to_param)
      end

      it 'renders the project template' do
        expect(response).to render_template('projects/classifies/show')
      end
    end

    context 'when there are no requests to classify' do
      let(:user) { FactoryBot.create(:user) }

      before do
        sign_in user
        ability.can :read, project
        project.info_requests.update_all(awaiting_description: false)
        get :show, params: { project_id: project.id }
      end

      it 'tells the user there are no requests to classify at the moment' do
        msg = 'There are no requests to classify right now. Great job!'
        expect(flash[:notice]).to eq(msg)
      end

      it 'redirects back to the project homepage' do
        expect(response).to redirect_to(project)
      end
    end

    context 'when there are only skipped requests to classify' do
      let(:user) { FactoryBot.create(:user) }

      before do
        sign_in user

        project.info_requests.classifiable.each do |info_request|
          queue.skip(info_request)
        end

        ability.can :read, project
        get :show, params: { project_id: project.id }
      end

      it 'clears the skipped queue' do
        skipped_requests =
          session['projects'][project.to_param]['classifiable']['skipped']

        expect(skipped_requests).to be_empty
      end

      it 'asks the user to have another go at the skipped requests' do
        msg = 'Nice work! How about having another try at the requests you ' \
              'skipped?'

        expect(flash[:notice]).to eq(msg)
      end

      it 'redirects back to the project homepage' do
        expect(response).to redirect_to(project)
      end
    end

    context 'with a logged in user who cannot read the project' do
      let(:user) { FactoryBot.create(:user) }

      before do
        sign_in user
        ability.cannot :read, project
      end

      it 'raises an CanCan::AccessDenied error' do
        expect {
          get :show, params: { project_id: project.id }
        }.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'logged out' do
      before { get :show, params: { project_id: project.id } }

      it 'redirects to sign in form' do
        expect(response.status).to eq 302
      end

      it 'saves a post redirect' do
        post_redirect = get_last_post_redirect

        expect(post_redirect.uri).to eq project_classify_path(project)
        expect(post_redirect.reason_params).to eq(
          web: 'To join this project',
          email: 'Then you can join this project',
          email_subject: 'Confirm your account on SITE'
        )
      end
    end
  end

  describe 'PATCH #skip' do
    let(:project) { FactoryBot.create(:project, requests_count: 1) }
    let(:ability) { Object.new.extend(CanCan::Ability) }

    before do
      allow(controller).to receive(:current_ability).and_return(ability)
      project.requests << FactoryBot.create(:awaiting_description)
    end

    context 'with a logged in user who can read the project' do
      let(:user) { FactoryBot.create(:user) }
      let(:skipped_request) { FactoryBot.create(:awaiting_description) }

      before do
        sign_in user
        ability.can :read, project
        project.requests << skipped_request
        patch :skip, params: { project_id: project.id,
                               url_title: skipped_request.url_title }
      end

      it 'assigns the project' do
        expect(assigns[:project]).to eq(project)
      end

      it 'skips the current request' do
        skipped_requests =
          session['projects'][project.to_param]['classifiable']['skipped']

        expect(skipped_requests).to include(skipped_request.to_param)
      end

      it 'confirms that the request has been skipped' do
        expect(flash[:notice]).to eq('Skipped!')
      end

      it 'redirects to another request to classify' do
        expect(response).to redirect_to(project_classify_path(project))
      end

      it "raises an ActiveRecord::RecordNotFound when the request can't be found" do
        expect {
          patch :skip, params: { project_id: project.id, url_title: 'foo' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with a logged in user who cannot read the project' do
      let(:user) { FactoryBot.create(:user) }

      before do
        sign_in user
        ability.cannot :read, project
      end

      it 'raises an CanCan::AccessDenied error' do
        expect {
          patch :skip, params: { project_id: project.id, url_title: 'foo' }
        }.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'logged out' do
      before do
        patch :skip, params: { project_id: project.id, url_title: 'foo' }
      end

      it 'redirects to sign in form' do
        expect(response.status).to eq 302
      end

      it 'saves a post redirect' do
        post_redirect = get_last_post_redirect

        expect(post_redirect.uri).to eq skip_project_classify_path(project)
        expect(post_redirect.reason_params).to eq(
          web: 'To join this project',
          email: 'Then you can join this project',
          email_subject: 'Confirm your account on SITE'
        )
      end
    end
  end

  shared_context 'project can be found' do
    let(:project) { FactoryBot.create(:project) }

    before do
      ability.can :read, project
      allow(Project).to receive(:find).with(project.id.to_s).and_return(project)
    end
  end

  shared_context 'request can be found' do
    include_context 'project can be found'

    let(:info_request) { FactoryBot.create(:info_request, user: user) }

    before do
      info_requests = double(:info_requests_collection)
      allow(project).to receive(:info_requests).and_return(info_requests)
      allow(info_requests).to receive(:classifiable).and_return(info_requests)
      allow(info_requests).to receive(:find_by!).
        with(url_title: info_request.url_title).and_return(info_request)
    end
  end

  describe 'POST #create' do
    let(:user) { FactoryBot.create(:pro_user) }
    let(:ability) { Object.new.extend(CanCan::Ability) }

    before do
      sign_in user
      allow(controller).to receive(:current_user).and_return(user)

      allow(controller).to receive(:current_ability).and_return(ability)
    end

    context 'project to be classified can not be found' do
      it 'raises a ActiveRecord::RecordNotFound error' do
        expect {
          post :create, params: { project_id: 'invalid' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'request to be classified can not be found' do
      include_context 'project can be found'

      it 'raises a ActiveRecord::RecordNotFound error' do
        expect {
          post :create, params: { project_id: project.id, url_title: 'invalid' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'url_title param not submitted' do
      include_context 'project can be found'

      it 'raises an ActionController::ParameterMissing error' do
        expect {
          post :create, params: { project_id: project.id }
        }.to raise_error(ActionController::ParameterMissing)
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
      before { ability.can :read, project }
    end

    shared_context 'classification can be submitted' do
      include_context 'user can classify request'

      let(:submissions) { double(:submissions_collection) }
      let(:submission) { instance_double(Project::Submission) }

      before do
        allow(project).to receive(:submissions).and_return(submissions)
        allow(submissions).to receive(:new).and_return(submission)
      end
    end

    context 'user is allowed to update the request' do
      include_context 'classification can be submitted'

      before { allow(submission).to receive(:save).and_return(true) }

      it 'create status_update log' do
        post_status('successful')

        event = InfoRequestEvent.last
        expect(event.event_type).to eq 'status_update'
        expect(event.params[:described_state]).to eq 'successful'
        expect(event.params[:old_described_state]).to eq 'waiting_response'
        expect(event.params).to include(
          user: { gid: info_request.user.to_global_id.to_s }
        )
      end

      it 'call set_described_state on the request' do
        expect(info_request).to receive(:set_described_state)
        post_status('successful')
      end

      it 'creates project submission' do
        event = instance_double(InfoRequestEvent)
        allow(controller).to receive(:set_described_state).and_return(event)
        expect(submissions).to receive(:new).with(
          user: user, info_request: info_request, resource: event
        ).and_return(submission)
        expect(submission).to receive(:save)
        post_status('successful')
      end

      it 'redirects the user to another request to classify' do
        post_status('successful')
        expect(response).to redirect_to(project_classify_path(project))
      end
    end

    context 'user sets the request as error_message without a message' do
      include_context 'user can classify request'

      it 'redirect the add message action' do
        post_status('error_message')
        expect(response).to redirect_to(
          message_project_classify_path(
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

        event = InfoRequestEvent.last
        expect(event.event_type).to eq 'status_update'
        expect(event.params[:described_state]).to eq 'error_message'
        expect(event.params[:old_described_state]).to eq 'waiting_response'
        expect(event.params[:message]).to eq 'A message'
        expect(event.params).to include(
          user: { gid: info_request.user.to_global_id.to_s }
        )
      end

      it 'call set_described_state on the request' do
        expect(info_request).to receive(:set_described_state)
        post_status('error_message', message: 'A message')
      end

      it 'redirects the user to another request to classify' do
        post_status('error_message', message: 'A message')
        expect(response).to redirect_to(project_classify_path(project))
      end
    end

    context 'user sets the request as requires_admin without a message' do
      include_context 'user can classify request'

      it 'redirect the add message action' do
        post_status('requires_admin')
        expect(response).to redirect_to(
          message_project_classify_path(
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

        event = InfoRequestEvent.last
        expect(event.event_type).to eq 'status_update'
        expect(event.params[:described_state]).to eq 'requires_admin'
        expect(event.params[:old_described_state]).to eq 'waiting_response'
        expect(event.params[:message]).to eq 'A message'
        expect(event.params).to include(
          user: { gid: info_request.user.to_global_id.to_s }
        )
      end

      it 'call set_described_state on the request' do
        expect(info_request).to receive(:set_described_state)
        post_status('requires_admin', message: 'A message')
      end

      it 'redirects the user to another request to classify' do
        post_status('requires_admin', message: 'A message')
        expect(response).to redirect_to(project_classify_path(project))
      end
    end
  end

  describe '#message' do
    include_examples 'request can be found'
    include_examples 'adding classification message action'

    let(:ability) { Object.new.extend(CanCan::Ability) }

    before do
      allow(controller).to receive(:current_ability).and_return(ability)
      ability.can :update_request_state, info_request
    end

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
