# -*- encoding : utf-8 -*-
require 'spec_helper'

describe(
  "notification_mailer/info_request_batches/_info_request_batch.text.erb") do
  let!(:public_body_1) { FactoryGirl.create(:public_body) }
  let!(:public_body_2) { FactoryGirl.create(:public_body) }
  let!(:batch_request) do
    batch = FactoryGirl.create(:info_request_batch,
                               title: "Something & something else",
                               public_bodies: [public_body_1, public_body_2])
    batch.create_batch!
    batch
  end
  let!(:batch_requests) { batch_request.info_requests.order(:created_at) }
  let!(:incoming_1) do
    FactoryGirl.create(:incoming_message, info_request: batch_requests.first)
  end
  let!(:incoming_2) do
    FactoryGirl.create(:incoming_message, info_request: batch_requests.second)
  end
  let!(:batch_notifications) do
    notifications = []

    event_1 = FactoryGirl.create(:response_event,
                                 incoming_message: incoming_1)
    notification_1 = FactoryGirl.create(:daily_notification,
                                        info_request_event: event_1)
    notifications << notification_1

    event_2 = FactoryGirl.create(:response_event,
                                 incoming_message: incoming_2)
    notification_2 = FactoryGirl.create(:daily_notification,
                                        info_request_event: event_2)
    notifications << notification_2

    notifications
  end
  let(:template) do
    "notification_mailer/info_request_batches/info_request_batch.text.erb"
  end

  before do
    render partial: template,
           locals: { info_request_batch: batch_request,
                     notifications: batch_notifications }
  end

  it "doesn't escape HTMLEntities in the request title" do
    expect(response).to include("Something & something else")
    expect(response).not_to include("Something &amp; something else")
  end

  it "renders the authority list partial" do
    expected_partial = "alaveteli_pro/info_request_batches/authority_list"
    expected_locals = { public_bodies: [public_body_1, public_body_2] }
    expect(response).
      to render_template(partial: expected_partial, locals: expected_locals)
  end

  it "renders the progress bar partial" do
    expected_partial = "alaveteli_pro/info_request_batches/progress_bar"
    expected_locals = { phases: batch_request.request_phases_summary,
                        batch: batch_request }
    expect(response).
      to render_template(partial: expected_partial, locals: expected_locals)
  end

  it "renders the notification partial for each event type" do
    expected_partial =
      "notification_mailer/info_request_batches/messages/response"
    expected_locals = { notifications: batch_notifications,
                        info_request_batch: batch_request }
    expect(response).
      to render_template(partial: expected_partial, locals: expected_locals)
  end
end
