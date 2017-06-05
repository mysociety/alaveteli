# -*- encoding : utf-8 -*-
require 'spec_helper'

describe NotificationMailer do
  describe '#daily_summary' do
    let!(:user) { FactoryGirl.create(:user) }

    let!(:public_body_1) do
      FactoryGirl.create(:public_body, name: "Ministry of fact keeping")
    end
    let!(:public_body_2) do
      FactoryGirl.create(:public_body, name: "Minor infractions quango")
    end

    let!(:info_request_1) do
      FactoryGirl.create(
        :info_request,
        title: "The cost of paperclips",
        public_body: public_body_1
      )
    end
    let!(:info_request_2) do
      FactoryGirl.create(
        :info_request,
        title: "Thefts of stationary",
        public_body: public_body_2
      )
    end
    let!(:batch_request) do
      batch = FactoryGirl.create(
        :info_request_batch,
        title: "Zero hours employees",
        user: user,
        public_bodies: [public_body_1, public_body_2]
      )
      batch.create_batch!
      batch
    end
    let!(:batch_requests) { batch_request.info_requests.order(:created_at) }

    # We need to force the ID numbers of these messages to be something known
    # so that we can predict the urls that will be included in the email
    let!(:incoming_1) do
      FactoryGirl.create(:incoming_message, info_request: info_request_1,
                                            id: 995)
    end
    let!(:incoming_2) do
      FactoryGirl.create(:incoming_message, info_request: info_request_2,
                                            id: 996)
    end
    let!(:incoming_3) do
      FactoryGirl.create(:incoming_message,
                         info_request: batch_requests.first,
                         id: 997)
    end
    let!(:incoming_4) do
      FactoryGirl.create(:incoming_message,
                         info_request: batch_requests.second,
                         id: 998)
    end

    let!(:notification_1) do
      event = FactoryGirl.create(:response_event,
                                 incoming_message: incoming_1)
      FactoryGirl.create(:daily_notification, info_request_event: event,
                                              user: user)
    end
    let!(:notification_2) do
      event = FactoryGirl.create(:response_event,
                                 incoming_message: incoming_2)
      FactoryGirl.create(:daily_notification, info_request_event: event,
                                              user: user)
    end
    let!(:batch_notifications) do
      notifications = []

      event_1 = FactoryGirl.create(:response_event,
                                   incoming_message: incoming_3)
      notification_1 = FactoryGirl.create(
        :daily_notification,
        info_request_event: event_1,
        user: user
      )
      notifications << notification_1

      event_2 = FactoryGirl.create(:response_event,
                                   incoming_message: incoming_4)
      notification_2 = FactoryGirl.create(
        :daily_notification,
        info_request_event: event_2,
        user: user
      )
      notifications << notification_2

      notifications
    end

    let(:all_notifications) do
      notifications = [notification_1, notification_2]
      notifications + batch_notifications
    end

    it "send the message to the right user" do
      mail = NotificationMailer.daily_summary(user, all_notifications)
      expect(mail.to).to eq [user.email]
    end

    it "send the message from the right address" do
      mail = NotificationMailer.daily_summary(user, all_notifications)
      expect(mail.from).to eq ['postmaster@localhost']
    end

    it "sets the right subject line" do
      mail = NotificationMailer.daily_summary(user, all_notifications)
      expect(mail.subject).
        to eq ("Your daily request summary from Alaveteli Professional")
    end

    it "matches the expected message" do
      mail = NotificationMailer.daily_summary(user, all_notifications)
      file_name = file_fixture_name("notification_mailer/daily-summary.txt")
      expected_message = File.open(file_name, 'r:utf-8') { |f| f.read }
      expect(mail.body.encoded).to eq(expected_message)
      expect(mail.body.encoded).to eq(expected_message)
    end

    it "sets reply_to headers" do
      mail = NotificationMailer.daily_summary(user, all_notifications)
      expected_reply_to = "#{AlaveteliConfiguration.contact_name} " \
                          "<#{AlaveteliConfiguration.contact_email}>"
      expect(mail.header["Reply-To"].value).to eq expected_reply_to
      expect(mail.header["Return-Path"].value).
        to eq 'do-not-reply-to-this-address@localhost'
    end

    it "sets auto-generated headers" do
      mail = NotificationMailer.daily_summary(user, all_notifications)
      expect(mail.header["Auto-Submitted"].value).to eq "auto-generated"
      expect(mail.header["X-Auto-Response-Suppress"].value).to eq "OOF"
    end
  end

  describe ".send_daily_notifications" do
    let(:now) { Time.zone.now }
    let!(:notification_1) do
      FactoryGirl.create(:daily_notification, send_after: now)
    end
    let!(:notification_2) do
      FactoryGirl.create(:daily_notification, send_after: now)
    end

    # These next three notifications test that we don't pull out users we
    # shouldn't
    let!(:future_notification) do
      FactoryGirl.create(
        :daily_notification,
        send_after: Time.zone.now + 1.hour
      )
    end
    let!(:seen_notification) do
      FactoryGirl.create(:daily_notification, seen_at: Time.zone.now)
    end
    let!(:instant_notification) { FactoryGirl.create(:instant_notification) }

    let(:expected_notifications) { [notification_1, notification_2] }

    it "calls #daily_summary for each appropriate user" do
      expect(NotificationMailer).
        to receive(:daily_summary).
          with(notification_1.user, [notification_1]).
            and_call_original
      expect(NotificationMailer).
        to receive(:daily_summary).
          with(notification_2.user, [notification_2]).
            and_call_original
      NotificationMailer.send_daily_notifications
    end

    it "sends a mail for each expected user" do
      ActionMailer::Base.deliveries.clear

      NotificationMailer.send_daily_notifications

      expect(ActionMailer::Base.deliveries.size).to eq 2

      first_mail = ActionMailer::Base.deliveries.first
      expect(first_mail.to).to eq([notification_1.user.email])

      second_mail = ActionMailer::Base.deliveries.second
      expect(second_mail.to).to eq([notification_2.user.email])
    end

    context "when a user has instant notifications as well as daily ones" do
      let(:info_request) do
        FactoryGirl.create(:info_request, user: notification_1.user)
      end
      let(:incoming_message) do
        FactoryGirl.create(:incoming_message, info_request: info_request)
      end
      let(:info_request_event) do
        FactoryGirl.create(:response_event,
                           incoming_message: incoming_message,
                           info_request: info_request
        )
      end
      let(:instant_notification) do
        FactoryGirl.create(:instant_notification,
                           info_request_event: info_request_event)
      end

      it "doesn't include the instant notifications in their daily email" do
        expect(NotificationMailer).
          to receive(:daily_summary).
            with(notification_1.user, [notification_1]).
              and_call_original
        expect(NotificationMailer).
          to receive(:daily_summary).
            with(notification_2.user, [notification_2]).
              and_call_original

        NotificationMailer.send_daily_notifications
      end
    end

    context "when a user has seen notifications as well as unseen ones" do
      let(:info_request) do
        FactoryGirl.create(:info_request, user: notification_1.user)
      end
      let(:incoming_message) do
        FactoryGirl.create(:incoming_message, info_request: info_request)
      end
      let(:info_request_event) do
        FactoryGirl.create(:response_event,
                           incoming_message: incoming_message,
                           info_request: info_request
        )
      end
      let(:seen_notification) do
        FactoryGirl.create(:daily_notification,
                           info_request_event: info_request_event,
                           seen_at: Time.zone.now)
      end

      it "doesn't include the seen notifications" do
        expect(NotificationMailer).
          to receive(:daily_summary).
            with(notification_1.user, [notification_1]).
              and_call_original
        expect(NotificationMailer).
          to receive(:daily_summary).
            with(notification_2.user, [notification_2]).
              and_call_original

        NotificationMailer.send_daily_notifications
      end
    end

    it "updates all of the notifications' seen_at timestamps" do
      expected_notifications.each { |n| expect(n.seen_at).to be_nil }

      NotificationMailer.send_daily_notifications

      expected_notifications.each do |n|
        n.reload
        expect(n.seen_at).to be_within(1.second).of(Time.zone.now)
      end
    end
  end
end
