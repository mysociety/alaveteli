require 'spec_helper'

RSpec.describe "quietly_try_to_open" do

  let(:controller) { double(ApplicationController) }
  let(:uri) { "http://example.com/feed" }

  before do
    stub_request(:get, uri)
  end

  it "should send a default timeout of 60 seconds" do
    expect(URI).to receive(:open).with(uri, read_timeout: 60).and_call_original
    controller.send(:quietly_try_to_open, uri)
  end

  it "should allow the timeout out be overriden" do
    expect(URI).to receive(:open).with(uri, read_timeout: 100).and_call_original
    controller.send(:quietly_try_to_open, uri, 100)
  end

end
