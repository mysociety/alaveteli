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

    it 'assigns the query' do
      get :index, params: { query: 'hello' }
      expect(assigns[:query]).to eq('hello')
    end

    it 'filters citations by the search query' do
      net = FactoryBot.create(:citation, source_url: 'https://example.net/a')
      org = FactoryBot.create(:citation, source_url: 'https://example.org/b')
      get :index, params: { query: 'example.net' }
      expect(assigns[:citations]).to include(net)
      expect(assigns[:citations]).not_to include(org)
    end

    it 'renders the correct template' do
      expect(response).to render_template(:index)
    end
  end
end
