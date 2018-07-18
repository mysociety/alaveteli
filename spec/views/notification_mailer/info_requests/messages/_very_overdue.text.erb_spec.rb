# -*- encoding : utf-8 -*-
require 'spec_helper'

describe("notification_mailer/info_requests/messages/_very_overdue.text.erb") do
  let!(:public_body) { FactoryBot.create(:public_body, name: "One & Two") }
  let!(:info_request) do
    FactoryBot.create(:overdue_request, public_body: public_body)
  end
  let!(:info_request_event) do
    FactoryBot.create(:overdue_event, info_request: info_request)
  end
  let!(:notification) do
    FactoryBot.create(:daily_notification,
                       info_request_event: info_request_event)
  end
  let(:template) do
    "notification_mailer/info_requests/messages/overdue"
  end

  before do
    allow(info_request).to receive(:law_used_human).and_return("FOI & EIR")
    render partial: template, locals: { info_request: info_request }
  end

  it "doesn't escape HTMLEntities in the public_body name" do
    expect(response).to include("One & Two")
    expect(response).not_to include("One &amp; Two")
  end

  it "doesn't escape HTMLEntities in the law used" do
    expect(response).to include("FOI & EIR")
    expect(response).not_to include("FOI &amp; EIR")
  end

  it "prints a link for the request" do
    target = respond_to_last_path(info_request, anchor: 'followup')
    expected_url = signin_url(r: target)
    expect(response).to have_text(expected_url)
  end
end
