require 'spec_helper'

RSpec.describe Admin::Users::SignInsController do
  before(:each) { basic_auth_login(@request) }

  describe 'GET #index' do
    let!(:sign_ins) do
      allow(AlaveteliConfiguration).
        to receive(:user_sign_in_activity_retention_days).and_return(1)
      FactoryBot.create_list(:user_sign_in, 3)
    end

    before { get :index }

    it 'returns a successful response' do
      expect(response).to be_successful
    end

    it 'assigns a page title' do
      expect(assigns[:title]).to eq('Listing user sign ins')
    end

    it 'collects sign ins' do
      expect(assigns[:sign_ins]).to match_array(sign_ins)
    end

    it 'renders the correct template' do
      expect(response).to render_template('index')
    end

    context 'with a search query' do
      let!(:search_target) do
        allow(AlaveteliConfiguration).
          to receive(:user_sign_in_activity_retention_days).and_return(1)
        FactoryBot.create(:user_sign_in, ip: '9.9.9.9')
      end

      before { get :index, params: { query: '9.9.9.9' } }

      it 'filters signins by the query' do
        expect(assigns[:sign_ins]).to match_array([search_target])
      end
    end
  end
end
