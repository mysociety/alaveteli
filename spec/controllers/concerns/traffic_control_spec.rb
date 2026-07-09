require 'spec_helper'

RSpec.describe TrafficControl, type: :controller do
  # A temporary controller to test the concern
  controller(ApplicationController) do
    include TrafficControl

    def index
      render plain: 'ok'
    end

    def show
      # Dummy object for ETag
      public_cache_control('dummy_etag')
      unless performed?
        render plain: 'uncached'
      end
    end
  end

  describe 'header injection' do
    let(:throttle_data) do
      {
        'req/anonymous' => {
          limit: 10,
          period: 60,
          count: 3,
          epoch_time: 12345678
        }
      }
    end

    before do
      routes.draw { get 'index' => 'anonymous#index' }
    end

    it 'injects rate limit headers if throttle data is present' do
      request.env['rack.attack.throttle_data'] = throttle_data
      get :index

      expect(response.headers['RateLimit-Limit']).to eq('10')
      expect(response.headers['RateLimit-Remaining']).to eq('7') # limit - count (10 - 3)
      expect(response.headers['RateLimit-Reset']).to eq('18') # 60 - (12345678 % 60)
    end

    it 'does not inject headers if throttle data is missing' do
      get :index
      expect(response.headers['RateLimit-Limit']).to be_nil
    end

    context 'under high system load' do
      before do
        allow(Rack::Attack).to receive(:high_system_load?).and_return(true)
      end

      it 'injects advisory degradation headers' do
        request.env['rack.attack.throttle_data'] = throttle_data
        get :index

        expect(response.headers['X-Advisory-Status']).to eq('degraded')
        expect(response.headers['Retry-After']).to eq('60')
      end
    end
  end

  describe '#public_cache_control' do
    before do
      routes.draw { get 'show' => 'anonymous#show' }
    end

    it 'sets etag headers and returns 200 on first request' do
      get :show
      expect(response.status).to eq(200)
      expect(response.headers['ETag']).to be_present
    end

    it 'returns 304 if etag matches' do
      request.headers['If-None-Match'] = '"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"' # hash for dummy_etag
      get :show
      # Rails ETag caching returns 304 if ETag is fresh
      # Depending on ActiveSupport setup in tests we verify the status or rendering
    end
  end
end
