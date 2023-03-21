require 'spec_helper'

RSpec.describe Health::MetricsController do
  describe 'GET index' do
    it 'returns a 200' do
      get :index, format: 'txt'
      expect(response.status).to eq(200)
    end

    it 'assigns sidekiq_stats' do
      get :index, format: 'txt'
      expect(assigns[:sidekiq_stats]).to_not be_nil
    end

    it 'assigns xapian_queued_jobs' do
      get :index, format: 'txt'
      expect(assigns[:xapian_queued_jobs]).to_not be_nil
    end

    it 'does not render a layout' do
      get :index, format: 'txt'
      expect(response).to render_template(layout: false)
    end
  end
end
