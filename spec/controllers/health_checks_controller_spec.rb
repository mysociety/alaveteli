# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HealthChecksController do

  describe 'GET index' do

    it 'returns a 200 if all health checks pass' do
      allow(HealthChecks).to receive_messages(:ok? => true)
      get :index
      expect(response.status).to eq(200)
    end

    it 'returns a 500 if the health check fails' do
      allow(HealthChecks).to receive_messages(:ok? => false)
      get :index
      expect(response.status).to eq(500)
    end

    it 'does not render a layout' do
      get :index
      expect(response).to render_template(:layout => false)
    end

  end

end
