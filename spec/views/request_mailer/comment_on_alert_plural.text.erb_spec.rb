require 'spec_helper'

describe "request_mailer/comment_on_alert_plural" do
  let(:request) { FactoryBot.create(:info_request) }
  let(:comment) { FactoryBot.create(:comment) }

  before do
    allow(AlaveteliConfiguration).to receive(:site_name).
      and_return("l'Information")
  end

  it "does not add HTMLEntities to the FOI law title" do
    allow(request).to receive(:legislation).and_return(
      FactoryBot.build(:legislation, short: "Test's Law")
    )
    assign(:info_request, request)
    assign(:comment, comment)
    render
    expect(response).to match("your Test's Law request")
  end

  it "does not add HTMLEntities to the site name" do
    assign(:info_request, request)
    assign(:comment, comment)
    render
    expect(response).to match("the l'Information team")
  end
end
