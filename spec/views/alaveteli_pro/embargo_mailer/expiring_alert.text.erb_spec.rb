# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "alaveteli_pro/embargo_mailer/expiring_alert.text.erb" do
  let(:pro_user) { FactoryGirl.create(:pro_user) }
  let!(:expiring_1) do
    FactoryGirl.create(:embargo_expiring_request, user: pro_user)
  end
  let!(:expiring_2) do
    FactoryGirl.create(:embargo_expiring_request, user: pro_user)
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
  end
end
