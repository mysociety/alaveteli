require 'spec_helper'

describe("notification_mailer/info_request_batches/messages/_embargo_expiring.text.erb") do
  let!(:public_body_1) { FactoryBot.create(:public_body, name: "One & Two") }
  let!(:public_body_2) { FactoryBot.create(:public_body) }
  let(:public_bodies) { [public_body_1, public_body_2] }
  let!(:batch_request) do
    travel_to(3.months.ago - 1.week) do
      batch = FactoryBot.create(:info_request_batch, :embargoed,
                                public_bodies: public_bodies)
      batch.create_batch!
      batch
    end
  end
  let!(:batch_requests) { batch_request.info_requests.order(:created_at) }
  let!(:batch_notifications) do
    notifications = []

    event_1 = FactoryBot.create(:embargo_expiring_event,
                                info_request: batch_requests.first)
    notification_1 = FactoryBot.create(:daily_notification,
                                       info_request_event: event_1)
    notifications << notification_1

    event_2 = FactoryBot.create(:embargo_expiring_event,
                                info_request: batch_requests.second)
    notification_2 = FactoryBot.create(:daily_notification,
                                       info_request_event: event_2)
    notifications << notification_2

    notifications
  end
  let(:template) do
    "notification_mailer/info_request_batches/messages/embargo_expiring"
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
      expected_url = request_url(info_request)
      expected_text = "#{public_body_name}: #{expected_url}"
      expect(response).to have_text(expected_text)
    end
  end

  context "when there are multiple responses" do
    it "prints pluralised messages" do
      expect(response).to have_text("2 requests will be made public")
      expect(response).to have_text("If you do not wish these requests to " \
                                    "go public at that time, please click " \
                                    "on the links below to keep them " \
                                    "private for longer.")
    end
  end

  context "when there's just one response" do
    it "prints singular messages" do
      response = render partial: template,
                        locals: { notifications: [batch_notifications.first] }
      expect(response).to have_text("1 request will be made public")
      expect(response).to have_text("If you do not wish this request to " \
                                    "go public at that time, please click " \
                                    "on the link below to keep it " \
                                    "private for longer.")
    end
  end
end
