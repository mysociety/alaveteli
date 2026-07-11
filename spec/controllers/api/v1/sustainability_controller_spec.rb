require 'spec_helper'

RSpec.describe Api::V1::SustainabilityController, type: :controller do
  describe 'GET #rate_limit' do
    let(:rule) do
      AlaveteliRateLimiter::Rule.new(
        :request,
        3,
        AlaveteliRateLimiter::Window.new(1, :hour)
      )
    end
    let(:limiter) { instance_double(AlaveteliRateLimiter::IPRateLimiter, rule: rule) }

    before do
      allow(AlaveteliRateLimiter::IPRateLimiter).
        to receive(:new).with(:request).and_return(limiter)
      allow(limiter).to receive(:records).with('127.0.0.1').and_return([])
      request.env['REMOTE_ADDR'] = '127.0.0.1'
    end

    it 'returns a versioned advisory contract without recording a request' do
      expect(limiter).not_to receive(:record)

      get :rate_limit

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
      expect(response.headers['Cache-Control']).to eq('no-store')
      expect(response.headers['RateLimit-Limit']).to eq('3')
      expect(response.headers['RateLimit-Remaining']).to eq('3')
      expect(response.headers['RateLimit-Reset']).to eq('0')
      expect(JSON.parse(response.body)).to eq(
        'version' => 1,
        'policy' => 'request',
        'limit' => 3,
        'remaining' => 3,
        'reset_in_seconds' => 0
      )
    end

    it 'reports active records without exposing them' do
      now = Time.current
      allow(Time).to receive(:current).and_return(now)
      recorded_at = now - 10.minutes
      allow(limiter).to receive(:records).with('127.0.0.1').
        and_return([recorded_at, now - 20.minutes])

      get :rate_limit

      body = JSON.parse(response.body)
      expect(body).to include(
        'version' => 1,
        'policy' => 'request',
        'limit' => 3,
        'remaining' => 1
      )
      expect(body).not_to have_key('records')
      expect(response.headers['RateLimit-Remaining']).to eq('1')
      expect(response.headers['RateLimit-Reset']).to eq('2400')
    end

    it 'reports zero remaining while preserving the oldest active reset' do
      now = Time.current
      allow(Time).to receive(:current).and_return(now)
      allow(limiter).to receive(:records).with('127.0.0.1').
        and_return([now - 20.minutes, now - 10.minutes, now - 5.minutes, now - 1.minute])

      get :rate_limit

      body = JSON.parse(response.body)
      expect(body).to include('limit' => 3, 'remaining' => 0, 'reset_in_seconds' => 2400)
      expect(response.headers['RateLimit-Remaining']).to eq('0')
      expect(response.headers['RateLimit-Reset']).to eq('2400')
    end

    it 'rejects an invalid client address without querying the limiter' do
      allow(request).to receive(:remote_ip).and_return('not-an-ip')
      expect(AlaveteliRateLimiter::IPRateLimiter).not_to receive(:new)

      get :rate_limit

      expect(response).to have_http_status(:bad_request)
      expect(response.headers['Cache-Control']).to eq('no-store')
      expect(response.body).to eq({ error: 'invalid_client_address' }.to_json)
    end

    it 'fails closed without exposing limiter details' do
      allow(limiter).to receive(:records).and_raise(StandardError, 'backend detail')

      get :rate_limit

      expect(response).to have_http_status(:service_unavailable)
      expect(response.headers['Cache-Control']).to eq('no-store')
      expect(response.body).to eq({ error: 'rate_limit_unavailable' }.to_json)
      expect(response.body).not_to include('backend detail')
    end
  end
end
