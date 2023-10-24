require 'spec_helper'

RSpec.describe Admin::ChangelogController do
  describe 'GET index' do
    render_views

    before do
      get :index
    end

    it 'renders the changelog as HTML' do
      expect(response.body).to match('<h2>Highlighted Features</h2>')
    end
  end
end
