# -*- encoding : utf-8 -*-
require 'spec_helper'

describe NotificationMailer do
  describe '#instant_notification' do
    let(:notification) { FactoryGirl.create(:instant_notification) }

    it 'returns a mail message to the user' do
      message = NotificationMailer.instant_notification(notification)
      expect(message.to).to eq([notification.user.email])
    end
  end

  describe '#response_notification' do
    let(:public_body) do
      FactoryGirl.create(:public_body, name: 'Test public body')
    end
    let(:info_request) do
      FactoryGirl.create(:info_request,
                         public_body: public_body,
                         title: "Here is a character that needs quoting …")
    end
    let(:incoming_message) do
      FactoryGirl.create(:incoming_message, info_request: info_request,
                                            id: 999)
    end
    let(:info_request_event) do
      FactoryGirl.create(:response_event, info_request: info_request,
                                          incoming_message: incoming_message)
    end
    let(:notification) do
      FactoryGirl.create(:notification,
                         info_request_event: info_request_event)
    end

    context "when the subject has characters which need quoting" do
      it 'should not error' do
        NotificationMailer.response_notification(notification)
      end
    end

    context "when the subject has characters which could be HTML escaped" do
      before do
        info_request.title = "Here's a request"
        info_request.save!
      end

      it 'should not create HTML entities' do
        mail = NotificationMailer.response_notification(notification)
        expected = "New response to your FOI request - Here's a request"
        expect(mail.subject).to eq expected
      end
    end

    it "sends the message to the right user" do
      mail = NotificationMailer.response_notification(notification)
      expect(mail.to).to eq [info_request.user.email]
    end

    it "sends the message from the right address" do
      mail = NotificationMailer.response_notification(notification)
      expect(mail.from).to eq ['postmaster@localhost']
    end

    it "sets reply_to headers" do
      mail = NotificationMailer.response_notification(notification)
      expected_reply_to = "#{AlaveteliConfiguration.contact_name} " \
                          "<#{AlaveteliConfiguration.contact_email}>"
      expect(mail.header["Reply-To"].value).to eq expected_reply_to
      expect(mail.header["Return-Path"].value).
        to eq 'do-not-reply-to-this-address@localhost'
    end

    it "sets auto-generated headers" do
      mail = NotificationMailer.response_notification(notification)
      expect(mail.header["Auto-Submitted"].value).to eq "auto-generated"
      expect(mail.header["X-Auto-Response-Suppress"].value).to eq "OOF"
    end

    it 'should send the expected message' do
      mail = NotificationMailer.response_notification(notification)
      file_name = file_fixture_name("notification_mailer/new_response.txt")
      expected_message = File.open(file_name, 'r:utf-8') { |f| f.read }
      expect(mail.body.encoded).to eq(expected_message)
    end

    context "when the user is a pro user" do
      let(:pro_user) { FactoryGirl.create(:pro_user) }

      before do
        info_request.user = pro_user
        info_request.save!
      end

      it 'should send the expected message' do
        mail = NotificationMailer.response_notification(notification)
        file_name = file_fixture_name(
          "notification_mailer/new_response_pro.txt"
        )
        expected_message = File.open(file_name, 'r:utf-8') { |f| f.read }
        expect(mail.body.encoded).to eq(expected_message)
      end
    end
  end
end
