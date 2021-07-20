require 'spec_helper'

RSpec.describe("notification_mailer/info_requests/messages/_embargo_expiring.text.erb") do
  let!(:info_request) { FactoryBot.create(:embargo_expiring_request) }
  let!(:info_request_event) do
    FactoryBot.create(:embargo_expiring_event, info_request: info_request)
  end
  let!(:notification) do
    FactoryBot.create(:daily_notification,
                      info_request_event: info_request_event)
  end
  let(:template) do
    "notification_mailer/info_requests/messages/embargo_expiring"
  end

  before do
    allow(AlaveteliConfiguration).
      to receive(:site_name).and_return("Something & something")
    render partial: template,
           locals: { info_request: info_request }
  end

  it "does not HTML escape the site name" do
    expect(response).to include("Something & something")
    expect(response).not_to include("Something &amp; something")
  end

  it "prints a link for the request" do
    expect(response).to have_text(request_url(info_request))
  end
end
