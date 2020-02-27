# -*- encoding : utf-8 -*-
require 'spec_helper'

describe(
  "notification_mailer/info_request_batches/messages/_very_overdue.text.erb"
) do
  let!(:public_body_1) { FactoryBot.create(:public_body, name: "One & Two") }
  let!(:public_body_2) { FactoryBot.create(:public_body) }
  let!(:batch_request) do
    batch = FactoryBot.create(:info_request_batch,
                              title: "Something & something else",
                              public_bodies: [public_body_1, public_body_2])
    batch.create_batch!
    batch
  end
  let!(:batch_requests) { batch_request.info_requests.order(:created_at) }
  let!(:batch_notifications) do
    notifications = []

    event_1 = FactoryBot.create(:very_overdue_event,
                                info_request: batch_requests.first)
    notification_1 = FactoryBot.create(:daily_notification,
                                       info_request_event: event_1)
    notifications << notification_1

    event_2 = FactoryBot.create(:very_overdue_event,
                                info_request: batch_requests.second)
    notification_2 = FactoryBot.create(:daily_notification,
                                       info_request_event: event_2)
    notifications << notification_2

    notifications
  end
  let(:template) do
    "notification_mailer/info_request_batches/messages/very_overdue"
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
      target = respond_to_last_path(info_request, anchor: 'followup')
      expected_url = signin_url(r: target)
      expected_text = "#{public_body_name}: #{expected_url}"
      expect(response).to have_text(expected_text)
    end
  end

  context "when there are multiple overdue requests" do
    it "prints pluralised messages" do
      expect(response).to have_text("2 requests have still not had " \
                                    "responses:")
      expect(response).to have_text("You can see the requests and tell " \
                                    "the bodies to respond with the " \
                                    "following links. You might like to " \
                                    "ask for internal reviews, asking the " \
                                    "bodies to find out why responses to " \
                                    "the requests have been so slow.")
    end
  end

  context "when there's just one overdue request" do
    it "prints singular messages" do
      response = render partial: template,
                        locals: { notifications: [batch_notifications.first] }
      expect(response).to have_text("1 request has still not had a response:")
      expect(response).to have_text("You can see the request and tell " \
                                    "the body to respond with the " \
                                    "following link. You might like to ask " \
                                    "for an internal review, asking them " \
                                    "to find out why their response to the " \
                                    "request has been so slow.")

    end
  end
end
