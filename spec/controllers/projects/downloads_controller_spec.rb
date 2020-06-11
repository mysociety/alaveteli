require 'spec_helper'

spec_meta = {
  type: :controller,
  feature: :projects
}

RSpec.describe Projects::DownloadsController, spec_meta do
  describe 'GET #show' do
    def show(format: 'csv')
      get :show, params: { project_id: '1', format: format }
    end

    let(:project) { FactoryBot.create(:project) }
    let(:ability) { Object.new.extend(CanCan::Ability) }

    before do
      allow(Project).to receive(:find).with('1').and_return(project)
      allow(controller).to receive(:current_ability).and_return(ability)
    end

    context 'when not authorised to download project' do
      before { ability.cannot :download, project }

      it 'raises access denied expection' do
        expect { show }.to raise_error(CanCan::AccessDenied)
      end
    end

    shared_context 'when authorised to download project' do
      before { ability.can :download, project }
    end

    context 'when HTML format' do
      include_context 'when authorised to download project'

      it 'is a bad request' do
        show(format: 'html')
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when CSV format' do
      include_context 'when authorised to download project'

      before { show }

      it 'is a successful request' do
        expect(response).to be_successful
      end

      it 'returns CSV data' do
        expect(response.body).to eq 'CSV_DATA'
      end

      it 'returns content disposition' do
        expect(response.header['Content-Disposition']).to eq 'attachment'
      end

      it 'returns CSV content type' do
        expect(response.header['Content-Type']).to eq 'text/csv'
      end
    end
  end
end
