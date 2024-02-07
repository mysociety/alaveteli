require 'spec_helper'

RSpec.describe Admin::CitationsController do
  before(:each) { basic_auth_login(@request) }

  describe 'GET index' do
    before { FactoryBot.create_list(:citation, 3) }
    before { get :index }

    it 'returns a successful response' do
      expect(response).to be_successful
    end

    it 'assigns the citations' do
      expect(assigns[:citations]).to all(be_a(Citation))
    end

    it 'renders the correct template' do
      expect(response).to render_template(:index)
    end
  end
end
