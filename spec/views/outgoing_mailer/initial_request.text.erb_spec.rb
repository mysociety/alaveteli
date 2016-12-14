# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe "outgoing_mailer/initial_request" do
  let(:body) { FactoryGirl.create(:public_body, :name => "Apostrophe's") }
  let(:request) { FactoryGirl.create(:info_request, :public_body => body) }
  let(:outgoing_message) { FactoryGirl.create(:initial_request) }

  it "does not add HTMLEntities to the public body name" do
    assign(:info_request, request)
    assign(:outgoing_message, outgoing_message)
    render
    expect(response).to match("requests to Apostrophe's")
  end

  it "does not add HTMLEntities to the FOI law title" do
    allow(request).to receive(:law_used_human).and_return("Test's Law")
    assign(:info_request, request)
    assign(:outgoing_message, outgoing_message)
    render
    expect(response).to match("the wrong address for Test's Law requests")
  end

  it "does not add HTMLEntities to the public body email address" do
    allow(body).to receive(:request_email).and_return("a'b@example.com")
    assign(:info_request, request)
    assign(:outgoing_message, outgoing_message)
    render
    expect(response).to match("Is a'b@example.com the wrong address")
  end
end
