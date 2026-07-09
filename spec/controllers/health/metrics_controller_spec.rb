require 'spec_helper'

RSpec.describe Health::MetricsController, type: :controller do
  describe 'GET index' do
    before do
      allow(Search).to receive(:queued_jobs_count).and_return(3)
      allow(Sidekiq::Queue).to receive(:new).
        and_return(double(:queue, latency: 12.5))
      allow(BotTrafficMetrics).to receive(:snapshot).and_return(
        bulk_export_requests: 2,
        bulk_export_unauthorized: 1,
        cache_hits: 8,
        cache_misses: 13,
        challenge_failed: 1,
        challenge_issued: 4,
        challenge_passed: 3,
        rate_limit_requests: 5
      )
    end

    it 'emits bot traffic and queue metrics' do
      get :index, format: :txt

      expect(response.body).to include(
        'sidekiq_default_queue_latency_seconds 12.5'
      )
      expect(response.body).to include(
        'bot_traffic_rate_limit_requests_total 5'
      )
      expect(response.body).to include(
        'bot_traffic_challenge_issued_total 4'
      )
      expect(response.body).to include(
        'bot_traffic_bulk_export_unauthorized_total 1'
      )
      expect(response.body).to include('bot_traffic_cache_hits_total 8')
      expect(response.body).to include('bot_traffic_cache_misses_total 13')
    end
  end
end
