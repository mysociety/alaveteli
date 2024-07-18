require 'spec_helper'

RSpec.describe Admin::DebugController do
  describe 'GET #index' do
    let(:admin_user) { FactoryBot.create(:admin_user) }

    it 'renders the view' do
      sign_in admin_user
      get :index
      expect(response).to render_template('index')
    end
  end
end
