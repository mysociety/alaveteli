# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliPro::PlansController do

  describe 'GET #index' do

    before do
      get :index
    end

    it 'renders the plans page' do
      expect(response).to render_template(:index)
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

  end

end
