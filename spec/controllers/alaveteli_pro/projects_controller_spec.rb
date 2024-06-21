require 'spec_helper'

RSpec.describe AlaveteliPro::ProjectsController, type: :controller do
  let(:pro_user) { FactoryBot.create(:pro_user) }
  let(:project) { FactoryBot.create(:project, owner: pro_user) }

  before { sign_in(pro_user) }

  describe 'GET #index' do
    it 'assigns @projects' do
      get :index
      expect(assigns(:projects)).to eq([project])
    end
  end

  describe 'GET #new' do
    it 'assigns a new project to @project' do
      get :new
      expect(assigns(:project)).to be_a_new(Project)
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      it 'creates a new project' do
        expect {
          post :create, params: { project: FactoryBot.attributes_for(:project) }
        }.to change(Project, :count).by(1)
      end

      it 'redirects to the next step' do
        post :create, params: { project: FactoryBot.attributes_for(:project) }
        expect(response).to redirect_to(
          project_path(Project.last)
        )
      end
    end

    context 'with invalid attributes' do
      it 'does not save the new project' do
        expect {
          post :create,
          params: { project: FactoryBot.attributes_for(:project, title: nil) }
        }.not_to change(Project, :count)
      end

      it 're-renders the new template' do
        post :create,
          params: { project: FactoryBot.attributes_for(:project, title: nil) }
        expect(response).to render_template(:new)
      end
    end
  end
end
