# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "notification_mailer/info_requests/messages/_response.text.erb" do
  let!(:notification) { FactoryBot.create(:notification) }
  let!(:info_request_event) { notification.info_request_event }
  let!(:incoming_message) { info_request_event.incoming_message }
  let!(:info_request) do
    info_request = info_request_event.info_request
    info_request.title = "Something & Something else"
    info_request.save!
    info_request
  end
  let!(:public_body) do
    public_body = info_request.public_body
    public_body.name = "One & Two"
    public_body.save!
    info_request.reload
    public_body
  end
  let(:template) { "notification_mailer/info_requests/messages/response" }

  before do
    allow(info_request).to receive(:law_used_human).and_return("FOI & EIR")
    render partial: template,
           locals: { info_request: info_request,
                     info_request_event: info_request_event }
  end

  it "prints a link to the response" do
    expected_url = incoming_message_url(incoming_message, cachebust: true)
    expect(response).to have_text(expected_url)
  end

  it "doesn't escape HTMLEntities in the law used" do
    expect(response).to include("FOI & EIR")
    expect(response).not_to include("FOI &amp; EIR")
  end

  it "doesn't escape HTMLEntities in info_request title" do
    expect(response).to include("Something & Something else")
    expect(response).not_to include("Something &amp; Something else")
  end

  it "doesn't escape HTMLEntities in the public_body name" do
    expect(response).to include("One & Two")
    expect(response).not_to include("One &amp; Two")
  end
end
