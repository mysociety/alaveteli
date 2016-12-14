# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe "request_mailer/stopped_responses" do
  let(:user) { FactoryGirl.create(:user, :name => "Test Us'r") }
  let(:body) { FactoryGirl.create(:public_body, :name => "Apostrophe's") }
  let(:request) do
    FactoryGirl.create(:info_request,
                       :public_body => body,
                       :user => user,
                       :title => "Request apostrophe's data")
  end

  before do
    allow(AlaveteliConfiguration).to receive(:site_name).
      and_return("l'Information")
    assign(:contact_email, "nospam@example.com")
  end

  it "does not add HTMLEntities to the FOI law title" do
    allow(request).to receive(:law_used_human).and_return("Test's Law")
    assign(:info_request, request)
    render
    expect(response).to match("an Test's Law request")
  end

  it "does not add HTMLEntities to the request title" do
    assign(:info_request, request)
    render
    expect(response).to match("Request apostrophe's data is an old request")
  end

  it "does not add HTMLEntities to the user name" do
    assign(:info_request, request)
    render
    expect(response).to match("sent to Test Us'r")
    expect(response).to match("on another subject to Test Us'r")
  end

  it "does not add HTMLEntities to the public body name" do
    assign(:info_request, request)
    render
    expect(response).to match("on behalf of Apostrophe's,")
  end

  it "does not add HTMLEntities to the contact email" do
    assign(:info_request, request)
    assign(:contact_email, "a'b@example.com")
    render
    expect(response).to match("email a'b@example.com for help")
  end

  it "does not add HTMLEntities to the site name" do
    assign(:info_request, request)
    render
    expect(response).to match("the l'Information team")
  end
end
