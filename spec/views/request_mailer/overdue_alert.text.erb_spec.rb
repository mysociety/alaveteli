# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe "request_mailer/overdue_alert" do
  let(:body) { FactoryGirl.create(:public_body, :name => "Apostrophe's") }
  let(:request) do
    FactoryGirl.create(:info_request,
                       :public_body => body,
                       :title => "Request apostrophe's data")
  end

  before do
    allow(AlaveteliConfiguration).to receive(:site_name).
      and_return("l'Information")
  end

  it "does not add HTMLEntities to the FOI law title" do
    allow(request).to receive(:law_used_human).and_return("Test's Law")
    assign(:info_request, request)
    render
    expect(response).to match("your Test's Law request")
  end

  it "does not add HTMLEntities to the request title" do
    assign(:info_request, request)
    render
    expect(response).to match("your FOI request Request apostrophe's data")
  end

  it "does not add HTMLEntities to the public body name" do
    assign(:info_request, request)
    render
    expect(response).to match("Apostrophe's have delayed")
    expect(response).to match("send a message to Apostrophe's")
  end

  it "does not add HTMLEntities to the site name" do
    assign(:info_request, request)
    render
    expect(response).to match("the l'Information team")
  end
end
