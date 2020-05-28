require 'spec_helper'

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
    let(:ability) { Object.new.extend(CanCan::Ability) }

    before do
      allow(controller).to receive(:current_ability).and_return(ability)
      project.requests << FactoryBot.create(:awaiting_description)
    end

    context 'with a logged in user who can read the project' do
      let(:user) { FactoryBot.create(:user) }

      before do
        session[:user_id] = user.id
        ability.can :read, project
        project.requests << FactoryBot.create(:awaiting_description)
        get :show, params: { project_id: project.id }
      end

      it 'assigns the project' do
        expect(assigns[:project]).to eq(project)
      end

      it 'assigns a queue for the current project and user' do
        queue = Project::Queue::Classifiable.new(project, session)
        expect(assigns[:queue]).to eq(queue)
      end

      it 'assigns an info_request from the queue' do
        queue = Project::Queue::Classifiable.new(project, session)
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
        session[:user_id] = user.id
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

        expect(post_redirect.uri).to eq project_classify_path(project)
        expect(post_redirect.reason_params).to eq(
          web: 'To join this project',
          email: 'Then you can join this project',
          email_subject: 'Confirm your account on SITE'
        )
      end
    end
  end
end
