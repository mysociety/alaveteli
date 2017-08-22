# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliPro::PlansController do

  describe 'GET #show' do

    before do
      get :show, id: 'pro'
    end

    it 'renders the plan page' do
      expect(response).to render_template(:show)
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

  end

end
