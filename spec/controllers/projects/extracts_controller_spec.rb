require 'spec_helper'

spec_meta = {
  type: :controller,
  feature: :projects
}

RSpec.describe Projects::ExtractsController, spec_meta do
  before do
    allow(controller).to receive(:site_name).and_return('SITE')
  end

  describe 'GET show' do
    let(:project) { FactoryBot.create(:project, requests_count: 1) }
    let(:ability) { Object.new.extend(CanCan::Ability) }

    before do
      allow(controller).to receive(:current_ability).and_return(ability)
    end

    context 'with a logged in user who can read the project' do
      let(:user) { FactoryBot.create(:user) }

      before do
        session[:user_id] = user.id
        ability.can :read, project
        project.requests << FactoryBot.create(:successful_request)
        get :show, params: { project_id: project.id }
      end

      it 'assigns the project' do
        expect(assigns[:project]).to eq(project)
      end

      it 'assigns a queue for the current project and user' do
        queue = Project::Queue::Extractable.new(project, session)
        expect(assigns[:queue]).to eq(queue)
      end

      it 'assigns an info_request from the queue' do
        queue = Project::Queue::Extractable.new(project, session)
        expect(queue).to include(assigns[:info_request])
      end

      it 'remembers the current request' do
        current_request_id =
          session['projects'][project.to_param]['extractable']['current']

        expect(current_request_id).to eq(assigns[:info_request].to_param)
      end

      it 'assigns the value set' do
        expect(assigns[:value_set]).to be_a(Dataset::ValueSet)
      end

      it 'renders the project template' do
        expect(response).to render_template('projects/extracts/show')
      end
    end

    context 'when there are no requests to extract' do
      let(:user) { FactoryBot.create(:user) }

      before do
        session[:user_id] = user.id
        ability.can :read, project
        project.info_requests.update_all(awaiting_description: false)
        get :show, params: { project_id: project.id }
      end

      it 'tells the user there are no requests to extract at the moment' do
        msg = 'There are no requests to extract right now. Great job!'
        expect(flash[:notice]).to eq(msg)
      end

      it 'edirects back to the project homepage' do
        expect(response).to redirect_to(project)
      end
    end

    context 'with a logged in user who cannot read the project' do
      let(:user) { FactoryBot.create(:user) }

      before do
        session[:user_id] = user.id
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

        expect(post_redirect.uri).to eq "/projects/#{ project.id }/extract"
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
      allow(Project).to receive(:find).with(project.id.to_s).and_return(project)
    end
  end

  shared_context 'request can be found' do
    include_context 'project can be found'

    let(:info_request) { FactoryBot.create(:info_request) }

    before do
      info_requests = double(:info_requests_collection)
      allow(project).to receive(:info_requests).and_return(info_requests)
      allow(info_requests).to receive(:extractable).and_return(info_requests)
      allow(info_requests).to receive(:find_by!).
        with(url_title: info_request.url_title).and_return(info_request)
    end
  end

  describe 'PATCH #update' do
    let(:project) { FactoryBot.create(:project, requests_count: 1) }
    let(:ability) { Object.new.extend(CanCan::Ability) }

    before do
      allow(controller).to receive(:current_ability).and_return(ability)
      project.requests << FactoryBot.create(:successful_request)
    end

    context 'with a logged in user who can read the project' do
      let(:user) { FactoryBot.create(:user) }
      let(:skipped_request) { FactoryBot.create(:successful_request) }

      before do
        session[:user_id] = user.id
        ability.can :read, project
        project.requests << skipped_request
        patch :update, params: { project_id: project.id,
                                 url_title: skipped_request.url_title }
      end

      it 'assigns the project' do
        expect(assigns[:project]).to eq(project)
      end

      it 'skips the current request' do
        skipped_requests =
          session['projects'][project.to_param]['extractable']['skipped']

        expect(skipped_requests).to include(skipped_request.to_param)
      end

      it 'confirms that the request has been skipped' do
        expect(flash[:notice]).to eq('Skipped!')
      end

      it 'redirects to another request to classify' do
        expect(response).to redirect_to(project_extract_path(project))
      end

      it "raises an ActiveRecord::RecordNotFound when the request can't be found" do
        expect {
          patch :update, params: { project_id: project.id, url_title: 'foo' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with a logged in user who cannot read the project' do
      let(:user) { FactoryBot.create(:user) }

      before do
        session[:user_id] = user.id
        ability.cannot :read, project
      end

      it 'raises an CanCan::AccessDenied error' do
        # TODO: Should check project access before trying to look up requests
        expect {
          patch :update, params: { project_id: project.id, url_title: 'foo' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'logged out' do
      before do
        patch :update, params: { project_id: project.id, url_title: 'foo' }
      end

      it 'redirects to sign in form' do
        expect(response.status).to eq 302
      end

      it 'saves a post redirect' do
        post_redirect = get_last_post_redirect

        expect(post_redirect.uri).to eq project_extract_path(project)
        expect(post_redirect.reason_params).to eq(
          web: 'To join this project',
          email: 'Then you can join this project',
          email_subject: 'Confirm your account on SITE'
        )
      end
    end
  end

  describe 'POST #create' do
    let(:project) { FactoryBot.create(:project, requests_count: 1) }
    let(:info_request) { project.info_requests.first }

    let(:user) { FactoryBot.create(:user) }
    let(:ability) { Object.new.extend(CanCan::Ability) }

    before do
      session[:user_id] = user&.id
      allow(controller).to receive(:current_user).and_return(user)

      allow(controller).to receive(:current_ability).and_return(ability)
    end

    context 'project can not be found' do
      it 'raises an ActiveRecord::RecordNotFound error' do
        expect {
          post :create, params: { project_id: 'invalid' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'request can not be found' do
      include_context 'project can be found'

      it 'raises an ActiveRecord::RecordNotFound error' do
        expect {
          post :create, params: { project_id: project.id, url_title: 'invalid' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    def post_extract(extract = nil)
      extract ||= { dataset_key_set_id: 1 }

      post :create, params: {
        extract: extract,
        project_id: project.id,
        url_title: info_request.url_title
      }
    end

    shared_context 'with a logged in user who can read the project' do
      include_context 'request can be found'
      before { ability.can :read, project }
    end

    shared_context 'extraction can be submitted' do
      include_context 'with a logged in user who can read the project'

      let(:submissions) { double(:submissions_collection) }
      let(:submission) { instance_double(Project::Submission) }

      before do
        allow(project).to receive(:submissions).and_return(submissions)
        allow(submissions).to receive(:new).and_return(submission)
      end
    end

    context 'submission created' do
      include_context 'extraction can be submitted'

      before { allow(submission).to receive(:save).and_return(true) }

      it 'initialises new value set with request' do
        params = {
          dataset_key_set_id: '1',
          values_attributes: [
            {
              dataset_key_id: '1',
              value: 'yes'
            }
          ]
        }
        expect(Dataset::ValueSet).to receive(:new).with(
          ActionController::Parameters.new(params).permit!
        )
        post_extract(params)
      end

      it 'creates project submission' do
        value_set = instance_double(Dataset::ValueSet)
        allow(Dataset::ValueSet).to receive(:new).and_return(value_set)
        expect(submissions).to receive(:new).with(
          user: user, info_request: info_request, resource: value_set
        ).and_return(submission)
        expect(submission).to receive(:save)
        post_extract
      end

      it 'redirects to next project extract' do
        post_extract
        expect(response).to redirect_to project_extract_path
      end
    end

    context 'submission validation fails' do
      include_context 'extraction can be submitted'

      before { expect(submission).to receive(:save).and_return(false) }

      it 'assigns the project' do
        post_extract
        expect(assigns[:project]).to eq(project)
      end

      it 'assigns the info request' do
        post_extract
        expect(assigns[:info_request]).to eq(info_request)
      end

      it 'assigns the value set' do
        post_extract
        expect(assigns[:value_set]).to be_a(Dataset::ValueSet)
      end

      it 'sets flash now error' do
        post_extract
        expect(flash.now[:error]).to eq("Extraction couldn't be saved.")
      end

      it 'renders show template' do
        post_extract
        expect(response).to render_template('show')
      end
    end

    context 'with invalid params' do
      include_context 'with a logged in user who can read the project'

      it 'assigns the project' do
        expect { post_extract({}) }.to raise_error(
          ActionController::ParameterMissing
        )
      end
    end

    context 'with a logged in user who cannot read the project' do
      include_context 'request can be found'

      before { ability.cannot :read, project }

      it 'raises an CanCan::AccessDenied error' do
        expect { post_extract }.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'logged out' do
      let(:user) { nil }

      before { post_extract }

      it 'redirects to sign in form' do
        expect(response.status).to eq 302
      end

      it 'saves a post redirect' do
        post_redirect = get_last_post_redirect

        expect(post_redirect.uri).to eq "/projects/#{ project.id }/extract"
        expect(post_redirect.reason_params).to eq(
          web: 'To join this project',
          email: 'Then you can join this project',
          email_subject: 'Confirm your account on SITE'
        )
      end
    end
  end
end
