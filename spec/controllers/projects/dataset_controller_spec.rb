require 'spec_helper'

spec_meta = {
  type: :controller,
  feature: :projects
}

RSpec.describe Projects::DatasetController, spec_meta do
  describe 'GET #show' do
    def show(format: 'csv')
      get :show, params: { project_id: '1', format: format }
    end

    let(:dataset_key_set) do
      FactoryBot.create(:dataset_key_set, resource: project)
    end

    let(:user) { FactoryBot.create(:user) }
    let(:project) { FactoryBot.create(:project) }
    let(:ability) { Object.new.extend(CanCan::Ability) }

    before do
      sign_in user
      allow(Project).to receive(:find).with('1').and_return(project)
      allow(controller).to receive(:current_ability).and_return(ability)
    end

    context 'when not authorised to view dataset key set' do
      before { ability.cannot :view, dataset_key_set }

      it 'raises access denied exception' do
        expect { show }.to raise_error(CanCan::AccessDenied)
      end
    end

    shared_context 'when authorised to view dataset key set' do
      before { ability.can :view, dataset_key_set }
    end

    context 'when HTML format' do
      include_context 'when authorised to view dataset key set'

      it 'renders show template' do
        show(format: 'html')
        expect(response).to render_template(:show)
      end
    end

    context 'when CSV format' do
      include_context 'when authorised to view dataset key set'

      before do
        allow(Project::Export).to receive(:new).with(project).and_return(
          double(to_csv: 'CSV_DATA', name: 'NAME')
        )
        show
      end

      it 'is a successful request' do
        expect(response).to be_successful
      end

      it 'returns CSV data' do
        expect(response.body).to eq 'CSV_DATA'
      end

      it 'returns content disposition' do
        expect(response.header['Content-Disposition']).to(
          eq 'attachment; filename="NAME"; filename*=UTF-8\'\'NAME'
        )
      end

      it 'returns CSV content type' do
        expect(response.header['Content-Type']).to eq 'text/csv'
      end
    end
  end

  describe 'PATCH #update' do
    let(:project) { FactoryBot.create(:project, owner: user) }
    let(:user) { FactoryBot.create(:user) }

    before { sign_in(user) }

    context 'when the user is authorized' do
      it 'updates the project' do
        patch :update, params: {
          project_id: project.id,
          project: { dataset_description: 'Updated description' }
        }
        project.reload
        expect(project.dataset_description.to_plain_text).
          to eq('Updated description')
      end

      it 'redirects to the project dataset show page' do
        patch :update, params: {
          project_id: project.id,
          project: { dataset_description: 'Updated description' }
        }
        expect(response).to redirect_to(project_dataset_path(project))
      end

      it 'sets a success flash notice' do
        patch :update, params: {
          project_id: project.id,
          project: { dataset_description: 'Updated description' }
        }
        expect(flash[:notice]).to eq('Dataset was successfully updated.')
      end
    end

    context 'when the user is not authorized' do
      before do
        allow(controller).to receive(:authorize!).with(:edit, project).
          and_raise(CanCan::AccessDenied)
      end

      it 'raises an authorization error' do
        expect {
          patch :update, params: { project_id: project.id, project: {} }
        }.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
