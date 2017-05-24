# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "notification_mailer/info_requests/_info_request.text.erb" do
  let(:notification) { FactoryGirl.create(:notification) }
  let(:info_request_event) { notification.info_request_event }
  let(:incoming_message) { info_request_event.incoming_message }
  let(:info_request) do
    info_request = info_request_event.info_request
    info_request.title = "Something & Something else"
    info_request.save!
    info_request
  end
  let(:template) do
    "notification_mailer/info_requests/info_request.text.erb"
  end

  before do
    render partial: template,
           locals: { info_request: info_request,
                     notifications: [notification] }
  end

  it "doesn't escape HTMLEntities in the request title" do
    expect(response).to include("Something & Something else")
    expect(response).not_to include("Something &amp; Something else")
  end

  it "renders the notification partial for the event type" do
    expected_partial = "notification_mailer/info_requests/messages/response"
    expected_locals = { info_request: info_request,
                        notification: notification,
                        info_request_event: info_request_event }
    expect(response).to render_template(partial: expected_partial,
                                        locals: expected_locals)
  end
end
