require 'spec_helper'

RSpec.describe 'Rack::Attack middleware rate limiting', type: :request do
  before :each do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  after :each do
    Rack::Attack.enabled = false
  end

  context 'when IP is anonymous' do
    let(:ip) { '1.2.3.4' }

    it 'allows up to 10 requests per minute' do
      10.times do
        get '/country_message', headers: { 'REMOTE_ADDR' => ip }
        expect(response.status).not_to eq(429)
      end
    end

    it 'throttles the 11th request' do
      11.times do |i|
        get '/country_message', headers: { 'REMOTE_ADDR' => ip }
        if i < 10
          expect(response.status).not_to eq(429)
        else
          expect(response.status).to eq(429)
        end
      end
    end
  end

  context 'when IP provides a verified bot token' do
    let(:ip) { '1.2.3.4' }
    let(:headers) { { 'REMOTE_ADDR' => ip, 'HTTP_X_FYI_BOT_TOKEN' => 'valid_secret_token' } }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('FYI_BOT_TOKEN').and_return('valid_secret_token')
    end

    it 'allows up to 100 requests per minute' do
      15.times do
        get '/country_message', headers: headers
        expect(response.status).not_to eq(429)
      end
    end
  end

  context 'when fail2ban triggers' do
    let(:ip) { '1.2.3.4' }

    it 'blocks the IP after 5 throttled requests' do
      10.times do
        get '/country_message', headers: { 'REMOTE_ADDR' => ip }
      end

      5.times do
        get '/country_message', headers: { 'REMOTE_ADDR' => ip }
        expect(response.status).to eq(429)
      end

      get '/country_message', headers: { 'REMOTE_ADDR' => ip }
      expect(response.status).to eq(403)
    end
  end

  context 'when Redis is down (circuit-breaker fallback)' do
    let(:ip) { '1.2.3.4' }

    before do
      # Simulate Redis error
      allow(Rack::Attack.cache).to receive(:write).and_raise(Redis::BaseError.new("Redis down"))
      allow(Rack::Attack.cache).to receive(:read).and_raise(Redis::BaseError.new("Redis down"))
      allow(Rack::Attack.cache).to receive(:count).and_raise(Redis::BaseError.new("Redis down"))
    end

    it 'fails open without 500 erroring the request' do
      get '/country_message', headers: { 'REMOTE_ADDR' => ip }
      expect(response.status).to eq(200)
    end
  end

  context 'when system load is high' do
    let(:ip) { '1.2.3.4' }

    before do
      # Mock system load to force dynamic restriction (limit set to 2rpm)
      allow(Rack::Attack).to receive(:high_system_load?).and_return(true)
    end

    it 'throttles the anonymous requests after 2 requests' do
      3.times do |i|
        get '/country_message', headers: { 'REMOTE_ADDR' => ip }
        if i < 2
          expect(response.status).not_to eq(429)
        else
          expect(response.status).to eq(429)
        end
      end
    end
  end
end
