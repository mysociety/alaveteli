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
        get :show, params: { project_id: project.id }
      end

      it 'assigns the project' do
        expect(assigns[:project]).to eq(project)
      end

      it 'renders the project template' do
        expect(response).to render_template('projects/extracts/show')
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
      allow(info_requests).to receive(:find_by!).
        with(url_title: info_request.url_title).and_return(info_request)
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
      before { allow(project).to receive(:submissions).and_return(submissions) }
    end

    context 'submission created' do
      include_context 'extraction can be submitted'

      before { allow(submissions).to receive(:create).and_return(true) }

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
          ActionController::Parameters.new(params).permit!.merge(
            resource: info_request
          )
        )
        post_extract(params)
      end

      it 'creates project submission' do
        value_set = instance_double(Dataset::ValueSet)
        allow(Dataset::ValueSet).to receive(:new).and_return(value_set)
        expect(submissions).to receive(:create).with(
          user: user, info_request: info_request, resource: value_set
        )
        post_extract
      end

      it 'redirects to next project extract' do
        post_extract
        expect(response).to redirect_to project_extract_path
      end
    end

    context 'submission validation fails' do
      include_context 'extraction can be submitted'

      before { expect(submissions).to receive(:create).and_return(false) }

      it 'assigns the project' do
        post_extract
        expect(assigns[:project]).to eq(project)
      end

      it 'assigns the info request' do
        post_extract
        expect(assigns[:info_request]).to eq(info_request)
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
