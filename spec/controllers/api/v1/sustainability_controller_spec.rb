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
      recorded_at = 10.minutes.ago
      allow(limiter).to receive(:records).with('127.0.0.1').
        and_return([recorded_at, 20.minutes.ago])

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
      expect(response.headers['RateLimit-Reset'].to_i).to be_between(2390, 2400)
    end

    it 'fails closed without exposing limiter details' do
      allow(limiter).to receive(:records).and_raise(StandardError, 'backend detail')

      get :rate_limit

      expect(response).to have_http_status(:service_unavailable)
      expect(response.body).to eq({ error: 'rate_limit_unavailable' }.to_json)
      expect(response.body).not_to include('backend detail')
    end
  end
end
