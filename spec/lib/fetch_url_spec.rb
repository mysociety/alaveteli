require 'spec_helper'

RSpec.describe "fetch_url" do
  let(:controller) { double(ApplicationController) }
  let(:uri) { "http://example.com/feed" }

  before do
    stub_request(:get, uri)
  end

  it "should send a default timeout of 60 seconds" do
    expect(URI).to receive(:open).with(uri, read_timeout: 60).and_call_original
    controller.send(:fetch_url, uri)
  end

  it "should allow the timeout out be overridden" do
    expect(URI).to receive(:open).with(uri, read_timeout: 100).and_call_original
    controller.send(:fetch_url, uri, timeout: 100)
  end
end

RSpec.describe "quietly_try_to_open" do
  let(:controller) { double(ApplicationController) }
  let(:uri) { "http://example.com/feed" }

  it "forwards to fetch_url with a deprecation warning" do
    allow(controller).to receive(:fetch_url).
      with(uri, timeout: 100).and_return('feed')
    expect(controller).to receive(:warn).with(/DEPRECATION/)
    expect(controller.send(:quietly_try_to_open, uri, 100)).to eq('feed')
  end
end
