# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Turnstile Challenge", type: :request do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('TURNSTILE_ENABLED').and_return('true')
    allow(ENV).to receive(:[]).with('TURNSTILE_SECRET_KEY').and_return('secret-key')
  end

  it "renders challenge html when suspicious request has not been verified" do
    get "/country_message", headers: {}, env: { 'rack.attack.throttle_data' => { 'req/ip' => { limit: 10, count: 11, period: 60, epoch_time: 12345 } } }
    
    expect(response.body).to include("Security Verification")
    expect(response.body).to include("cf-turnstile")
  end

  it "bypasses verification if Turnstile validation succeeds" do
    expect(TurnstileValidator).to receive(:validate).with("mock-token", "127.0.0.1").and_return(true)
    
    post "/country_message", params: { cf_turnstile_response: "mock-token" }, env: { 'rack.attack.throttle_data' => { 'req/ip' => { limit: 10, count: 11, period: 60, epoch_time: 12345 } } }
    
    expect(session[:turnstile_verified]).to be(true)
  end
end
