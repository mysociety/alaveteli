require 'spec_helper'

RSpec.describe AlaveteliPro::ProjectsController, type: :controller do
  let(:ability) { Object.new.extend(CanCan::Ability) }

  let(:pro_user) { FactoryBot.create(:pro_user) }
  let(:project) { FactoryBot.create(:project, owner: pro_user) }

  before do
    sign_in(pro_user)
    ability.can :edit, project
    allow(controller).to receive(:current_ability).and_return(ability)
  end

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

  describe 'GET #edit' do
    it 'assigns the requested project to @project' do
      get :edit, params: { id: project.id }
      expect(assigns(:project)).to eq(project)
    end
  end

  describe 'PATCH #update' do
    context 'with valid attributes' do
      it 'updates the project' do
        patch :update,
          params: { id: project.id, project: { title: 'Updated Title' } }
        project.reload
        expect(project.title).to eq('Updated Title')
      end

      it 'redirects to the project' do
        patch :update,
          params: { id: project.id, project: { title: 'Updated Title' } }
        expect(response).to redirect_to(project_path(Project.last))
      end
    end

    context 'when new project session and with valid attributes' do
      before do
        session[:new_project] = true
        allow(controller).to receive(:project_params).and_return({})
      end

      it 'redirects to project' do
        patch :update,
          params: { id: project.id, step: 'edit' }
        expect(response).to redirect_to(
          project_path(Project.last)
        )
      end
    end

    context 'with invalid attributes' do
      it 'does not update the project' do
        patch :update,
          params: { id: project.id, step: 'edit', project: { title: nil } }
        project.reload
        expect(project.title).not_to be_nil
      end

      it 're-renders the edit template' do
        patch :update,
          params: { id: project.id, step: 'edit', project: { title: nil } }
        expect(response).to render_template(:edit)
      end
    end
  end
end
