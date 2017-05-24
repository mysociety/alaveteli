# -*- encoding : utf-8 -*-
require 'spec_helper'

describe(
  "notification_mailer/info_request_batches/messages/_response.text.erb") do
  let!(:public_body_1) { FactoryGirl.create(:public_body, name: "One & Two") }
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
    "notification_mailer/info_request_batches/messages/response"
  end

  before do
    render partial: template,
           locals: { notifications: batch_notifications }
  end

  it "doesn't escape HTMLEntities in public body names" do
    expect(response).to include("One & Two")
    expect(response).not_to include("One &amp; Two")
  end

  it "prints a link for each notification" do
    batch_notifications.each do |notification|
      info_request = notification.info_request_event.info_request
      public_body_name = info_request.public_body.name
      incoming_message = notification.info_request_event.incoming_message
      expected_url = incoming_message_url(incoming_message, :cachebust => true)
      expected_text = "#{public_body_name}: #{expected_url}"
      expect(response).to have_text(expected_text)
    end
  end

  context "when there are multiple responses" do
    it "prints pluralised messages" do
      expect(response).to have_text("2 requests had new responses:")
      expect(response).to have_text("You can see the responses with the " \
                                    "following links:")
    end
  end

  context "when there's just one response" do
    it "prints singular messages" do
      response = render partial: template,
                        locals: { notifications: [batch_notifications.first] }
      expect(response).to have_text("1 request had a new response:")
      expect(response).to have_text("You can see the response with the " \
                                    "following link:")
    end
  end
end
