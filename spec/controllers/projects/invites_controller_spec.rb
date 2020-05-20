require 'spec_helper'

spec_meta = {
  type: :controller,
  feature: :projects
}

RSpec.describe Projects::InvitesController, spec_meta do
  before do
    allow(controller).to receive(:site_name).and_return('SITE')
  end

  describe 'GET #create' do
    let(:project) { FactoryBot.create(:project, :with_invite_token) }

    context 'with a logged in user who is not a contributor' do
      let(:user) { FactoryBot.create(:user) }

      before do
        session[:user_id] = user.id
        get :create, params: { token: project.invite_token }
      end

      it 'assigns the project' do
        expect(assigns[:project]).to eq(project)
      end

      it 'makes the user a contributor of the project' do
        expect(project.reload.contributors).to include(user)
      end

      it 'tells the user they have joined the project' do
        expect(flash[:notice]).to eq('Welcome to the project!')
      end

      it 'redirects to the project' do
        expect(response).to redirect_to(project)
      end
    end

    context 'with a logged in member' do
      let(:user) { FactoryBot.create(:user) }

      before do
        session[:user_id] = user.id
        project.contributors << user
        get :create, params: { token: project.invite_token }
      end

      it 'tells the user they are already a member' do
        msg = 'You are already a member of this project'
        expect(flash[:notice]).to eq(msg)
      end

      it 'redirects to the project' do
        expect(response).to redirect_to(project)
      end
    end

    context 'with a logged in owner' do
      let(:user) { project.owner }

      before do
        session[:user_id] = user.id
        get :create, params: { token: project.invite_token }
      end

      it 'tells the user they are already a member' do
        msg = 'You are already a member of this project'
        expect(flash[:notice]).to eq(msg)
      end

      it 'redirects to the project' do
        expect(response).to redirect_to(project)
      end
    end

    context 'logged in but invalid URL' do
      let(:user) { project.owner }

      before do
        session[:user_id] = user.id
      end

      it 'raises ActiveRecord::RecordNotFound with an invalid token param' do
        expect {
          get :create, params: { token: 'invalid' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'logged out' do
      before { get :create, params: { token: project.invite_token } }

      it 'redirects to sign in form' do
        expect(response.status).to eq 302
      end

      it 'saves a post redirect' do
        post_redirect = get_last_post_redirect

        expect(post_redirect.uri).to eq "/p/#{ project.invite_token }"
        expect(post_redirect.reason_params).to eq(
          web: 'To join this project',
          email: 'Then you can join this project',
          email_subject: 'Confirm your account on SITE'
        )
      end
    end
  end
end
