require 'spec_helper'

spec_meta = {
  type: :controller,
  feature: :projects
}

RSpec.describe Projects::ContributorsController, spec_meta do
  before do
    allow(controller).to receive(:site_name).and_return('SITE')
  end

  describe 'DELETE destroy' do
    let(:project) { FactoryBot.create(:project) }
    let(:ability) { Object.new.extend(CanCan::Ability) }

    before do
      allow(controller).to receive(:current_ability).and_return(ability)
    end

    context 'when a member can remove the contributor' do
      let(:user) { FactoryBot.create(:user) }

      before do
        project.contributors << user

        ability.can :read, project
        ability.can :remove_contributor, user

        session[:user_id] = user.id
        delete :destroy, params: { project_id: project.id, id: user.id }
      end

      it 'assigns the project' do
        expect(assigns[:project]).to eq(project)
      end

      it 'removes the user from the project' do
        expect(project.reload.contributors).not_to include(user)
      end

      it 'tells the user they are no longer a member of the project' do
        msg = 'You have left the project.'
        expect(flash[:notice]).to eq(msg)
      end

      it 'redirects to the homepage' do
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when a member cannot remove the contributor' do
      let(:user) { FactoryBot.create(:user) }

      before do
        project.contributors << user

        ability.can :read, project
        ability.cannot :remove_contributor, user

        session[:user_id] = user.id
      end

      it 'raises an CanCan::AccessDenied error' do
        expect {
          delete :destroy, params: { project_id: project.id, id: user.id }
        }.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'with a logged in user who cannot read the project' do
      let(:user) { FactoryBot.create(:user) }
      let(:contributor) { FactoryBot.create(:user) }

      before do
        project.contributors << contributor
        session[:user_id] = user.id
      end

      it 'raises an CanCan::AccessDenied error' do
        expect {
          delete :destroy,
                 params: { project_id: project.id, id: contributor.id }
        }.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'logged out' do
      before { delete :destroy, params: { project_id: project.id, id: 1 } }

      it 'redirects to sign in form' do
        expect(response.status).to eq 302
      end

      it 'saves a post redirect' do
        post_redirect = get_last_post_redirect

        expect(post_redirect.uri).to eq project_path(project)
        expect(post_redirect.reason_params).to eq(
          web: 'To leave this project',
          email: 'Then you can leave this project',
          email_subject: 'Confirm your account on SITE'
        )
      end
    end
  end
end
