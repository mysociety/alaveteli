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
end
