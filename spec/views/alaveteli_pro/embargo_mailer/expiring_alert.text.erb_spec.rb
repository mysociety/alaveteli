require 'spec_helper'

describe "alaveteli_pro/embargo_mailer/expiring_alert.text.erb" do
  let(:pro_user) { FactoryBot.create(:pro_user) }
  let!(:expiring_1) do
    FactoryBot.create(:embargo_expiring_request, user: pro_user)
  end
  let!(:expiring_2) do
    FactoryBot.create(:embargo_expiring_request, user: pro_user)
  end

  before do
    allow(AlaveteliConfiguration).
      to receive(:site_name).and_return("Something & something")
  end

  context "when there is a single request" do
    before do
      assign(:info_requests, [expiring_1])
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
                      "  #{request_url(expiring_1)}\n\n" \
                      "-- the Something & something team\n"
      expect(response).to eq expected_body
    end
  end

  context "when there are multiple requests" do
    before do
      assign(:info_requests, [expiring_1, expiring_2])
      render
    end

    it "does not HTML escape the site name" do
      expect(response).to match("Something & something")
      expect(response).not_to match("Something &amp; something")
    end

    it "prints the message correctly" do
      expected_body = "The following requests will be made public on " \
                      "Something & something in the next week. If you do " \
                      "not wish for any of these requests to go public, " \
                      "please click on the links below to extend them.\n\n" \
                      "  #{request_url(expiring_1)}\n" \
                      "  #{request_url(expiring_2)}\n\n" \
                      "-- the Something & something team\n"
      expect(response).to eq expected_body
    end
  end
end
