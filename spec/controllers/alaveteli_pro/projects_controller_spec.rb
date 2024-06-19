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
end
