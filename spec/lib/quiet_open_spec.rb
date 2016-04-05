# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "quietly_try_to_open" do

  let(:controller) { double(ApplicationController) }
  let(:empty_stream) { double(URI::HTTP) }
  let(:uri) { "http://example.com/feed" }

  before do
    allow(empty_stream).to receive(:read).and_return("")
  end

  it "should send a default timeout of 60 seconds" do
    expect(controller).to receive(:open).with(uri, {:read_timeout=>60}).
      and_return(empty_stream)
    controller.send(:quietly_try_to_open, uri)
  end

  it "should allow the timeout out be overriden " do
    expect(controller).to receive(:open).with(uri, {:read_timeout=>100}).
      and_return(empty_stream)
    controller.send(:quietly_try_to_open, uri, 100)
  end

end
