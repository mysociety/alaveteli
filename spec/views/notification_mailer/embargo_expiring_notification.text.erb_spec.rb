require 'spec_helper'

describe "notification_mailer/embargo_expiring_notification.text.erb" do
  let!(:info_request) do
    FactoryBot.create(:embargo_expiring_request)
  end

  before do
    allow(AlaveteliConfiguration).
      to receive(:site_name).and_return("Something & something")
  end

  before do
    assign(:info_request, info_request)
    render
  end

  it "does not HTML escape the site name" do
    expect(response).to match("Something & something")
    expect(response).not_to match("Something &amp; something")
  end

  it "prints the message correctly" do
    expected_body = "The following request will be made public on " \
                    "Something & something in the next week. If you do " \
                    "not wish this request to go public at that time, " \
                    "please click on the link below to keep it private " \
                    "for longer.\n\n" \
                    "#{request_url(info_request)}\n\n" \
                    "-- the Something & something team\n"
    expect(response).to eq expected_body
  end
end
