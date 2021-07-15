require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe "request_mailer/new_response" do
  let(:incoming_message) { FactoryBot.create(:incoming_message) }
  let(:request) { incoming_message.info_request }

  before do
    allow(AlaveteliConfiguration).to receive(:site_name).
      and_return("l'Information")
  end

  it "does not add HTMLEntities to the FOI law title" do
    allow(request).to receive(:legislation).and_return(
      FactoryBot.build(:legislation, full: "Test's Law")
    )
    assign(:info_request, request)
    assign(:incoming_message, incoming_message)
    render
    expect(response).to match("the Test's Law request")
  end

  it "does not add HTMLEntities to the site name" do
    assign(:info_request, request)
    assign(:incoming_message, incoming_message)
    render
    expect(response).to match("the l'Information team")
  end
end
