# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe "request_mailer/not_clarified_alert" do
  let(:body) { FactoryBot.create(:public_body, :name => "Apostrophe's") }
  let(:request) { FactoryBot.create(:info_request, :public_body => body) }

  before do
    allow(AlaveteliConfiguration).to receive(:site_name).
      and_return("l'Information")
  end

  it "does not add HTMLEntities to the FOI law title" do
    allow(request).to receive(:legislation).and_return(
      FactoryBot.build(:legislation, short: "Test's Law")
    )
    assign(:info_request, request)
    render
    expect(response).to match("your Test's Law request")
  end

  it "does not add HTMLEntities to the public body name" do
    assign(:info_request, request)
    render
    expect(response).to match("Apostrophe's has asked you to explain")
  end

  it "does not add HTMLEntities to the site name" do
    assign(:info_request, request)
    render
    expect(response).to match("the l'Information team")
  end
end
