require 'spec_helper'

RSpec.describe RequestMailbox do
  describe '#process' do
    before(:each) do
      ActionMailer::Base.deliveries = []
    end

    it "should append it to the appropriate request" do
      ir = info_requests(:fancy_dog_request)
      expect(ir.incoming_messages.count).to eq(1) # in the fixture
      receive_incoming_mail('incoming-request-plain.eml',
                            to: ir.incoming_email)
      expect(ir.incoming_messages.count).to eq(2) # one more arrives
      expect(ir.info_request_events[-1].incoming_message_id).not_to be_nil

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      # to the user who sent fancy_dog_request
      expect(mail.to).to eq(['bob@localhost'])
      deliveries.clear
    end

    it "should append it to the appropriate request if there is only one guess of information request" do
      ir = info_requests(:fancy_dog_request)
      expect(ir.incoming_messages.count).to eq(1) # in the fixture
      receive_incoming_mail(
        'incoming-request-plain.eml',
        to: "request-#{ir.id}-#{ir.idhash}a@localhost"
      )
      expect(ir.incoming_messages.count).to eq(2) # one more arrives
      expect(ir.info_request_events[-1].incoming_message_id).not_to be_nil
      expect(ir.info_request_events[-2].params[:editor]).to eq("automatic")

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      # to the user who sent fancy_dog_request
      expect(mail.to).to eq(['bob@localhost'])
      deliveries.clear
    end

    it "should append the email to each exact request address, unless that request has already received the email" do
      ir = info_requests(:fancy_dog_request)
      inbound_email = <<~EML
        From: EMAIL_FROM
        To: EMAIL_TO
        Message-ID: abcdefg@example.com
        Subject: Basic Email

        Hello, World
      EML
      expect(ir.incoming_messages.count).to eq(1) # in the fixture
      receive_incoming_mail(
        inbound_email,
        to: ir.incoming_email
      )
      expect(ir.incoming_messages.count).to eq(2) # one more arrives
      # send the email again
      receive_incoming_mail(
        inbound_email,
        to: ir.incoming_email
      )
      # this shouldn't add to the number of incoming mails
      expect(ir.incoming_messages.count).to eq(2)
      # send an email with a new Message-ID
      inbound_email = <<~EML
        From: EMAIL_FROM
        To: EMAIL_TO
        Message-ID: ab@example.com
        Subject: Basic Email

        Hello, World
      EML
      receive_incoming_mail(
        inbound_email,
        to: ir.incoming_email
      )
      # this should add to the number of incoming mails
      expect(ir.incoming_messages.count).to eq(3)
    end

    it 'should append the email to every request matches, unless the requests has already received the email' do
      info_request_1 = FactoryBot.create(:info_request)
      info_request_2 = FactoryBot.create(:info_request)

      expect(info_request_1.incoming_messages.count).to eq(0)
      expect(info_request_2.incoming_messages.count).to eq(0)

      inbound_email = <<~EML
        From: EMAIL_FROM
        To: EMAIL_TO
        Message-ID: ab@example.com
        Subject: Basic Email

        Hello, World
      EML

      # send email to one request
      receive_incoming_mail(
        inbound_email,
        to: info_request_1.incoming_email
      )

      expect(info_request_1.incoming_messages.count).to eq(1)
      expect(info_request_2.incoming_messages.count).to eq(0)

      # send same email to both requests, should only be delivered to the
      # request which hasn't already received the email
      receive_incoming_mail(
        inbound_email,
        to: [
          info_request_1.incoming_email,
          info_request_2.incoming_email
        ].join(', ')
      )

      expect(info_request_1.incoming_messages.count).to eq(1)
      expect(info_request_2.incoming_messages.count).to eq(1)
    end

    it "should store mail in holding pen and send to admin when the email is not to any information request" do
      ir = info_requests(:fancy_dog_request)
      expect(ir.incoming_messages.count).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(0)
      receive_incoming_mail('incoming-request-plain.eml',
                            to: 'dummy@localhost')
      expect(ir.incoming_messages.count).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(1)
      last_event = InfoRequest.holding_pen_request.info_request_events.last
      expect(last_event.params[:rejected_reason]).
        to eq("Could not identify the request from the email address")

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq([AlaveteliConfiguration.contact_email])
      deliveries.clear
    end

    it "puts messages with a malformed To: in the holding pen" do
      request = FactoryBot.create(:info_request)
      receive_incoming_mail('incoming-request-plain.eml', to: 'asdfg')
      expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(1)
    end

    it "attaches messages with an info request address in the Received headers to the appropriate request" do
      ir = info_requests(:fancy_dog_request)
      expect(ir.incoming_messages.count).to eq(1) # in the fixture
      mail_content = <<~EOF
        From: "FOI Person" <foiperson@localhost>
        Received: from smtp-out.localhost
                by example.net with esmtps
                (Exim 4.89)
                (envelope-from <foiperson@localhost.co>)
                id ABC
                for #{ir.incoming_email}.com; Mon, 23 Nov 2020 00:00:00 +0000
        Test
      EOF
      receive_incoming_mail(mail_content)
      expect(ir.incoming_messages.count).to eq(2) # one more arrives
      expect(ir.info_request_events[-1].incoming_message_id).not_to be_nil

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      # to the user who sent fancy_dog_request
      expect(mail.to).to eq(['bob@localhost'])
      deliveries.clear
    end

    it "should parse attachments from mails sent with apple mail" do
      ir = info_requests(:fancy_dog_request)
      expect(ir.incoming_messages.count).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(0)
      receive_incoming_mail('apple-mail-with-attachments.eml',
                            to: 'dummy@localhost')
      expect(ir.incoming_messages.count).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(1)
      last_event = InfoRequest.holding_pen_request.info_request_events.last
      expect(last_event.params[:rejected_reason]).
        to eq("Could not identify the request from the email address")

      im = IncomingMessage.last
      # Check that the attachments haven't been somehow loaded from a
      # previous test run
      expect(im.foi_attachments.size).to eq(0)

      # Trace where attachments first get loaded:
      # TODO: Ideally this should be 3, but some html parts from Apple Mail
      # are being treated like attachments
      im.extract_attachments!
      expect(im.foi_attachments.size).to eq(6)

      # Clean up
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq([AlaveteliConfiguration.contact_email])
      deliveries.clear
    end

    it "should store mail in holding pen and send to admin when the from email is empty and only authorities can reply" do
      ir = info_requests(:fancy_dog_request)
      ir.allow_new_responses_from = 'authority_only'
      ir.handle_rejected_responses = 'holding_pen'
      ir.save!
      expect(ir.incoming_messages.count).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(0)
      receive_incoming_mail('incoming-request-plain.eml',
                             to: ir.incoming_email,
                             from: "")
      expect(ir.incoming_messages.count).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(1)
      last_event = InfoRequest.holding_pen_request.info_request_events.last
      expect(last_event.params[:rejected_reason]).
        to match(/there is no "From" address/)

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq([AlaveteliConfiguration.contact_email])
      deliveries.clear
    end

    it "should store mail in holding pen and send to admin when the from email is unknown and only authorities can reply" do
      ir = info_requests(:fancy_dog_request)
      ir.allow_new_responses_from = 'authority_only'
      ir.handle_rejected_responses = 'holding_pen'
      ir.save!
      expect(ir.incoming_messages.count).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(0)
      receive_incoming_mail('incoming-request-plain.eml',
                            to: ir.incoming_email,
                            from: "frob@nowhere.com")
      expect(ir.incoming_messages.count).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(1)
      last_event = InfoRequest.holding_pen_request.info_request_events.last
      expect(last_event.params[:rejected_reason]).
        to match(/Only the authority can reply/)

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq([AlaveteliConfiguration.contact_email])
      deliveries.clear
    end

    context "when sent from known spam address" do
      before do
        @spam_address = FactoryBot.create(:spam_address)
      end

      it "recognises a spam address under the 'To' header" do
        receive_incoming_mail('incoming-request-plain.eml',
                              to: @spam_address.email)

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(0)
        deliveries.clear
      end

      it "recognises a spam address under the 'CC' header" do
        receive_incoming_mail('incoming-request-plain.eml',
                              cc: @spam_address.email)

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(0)
        deliveries.clear
      end

      it "recognises a spam address under the 'BCC' header" do
        receive_incoming_mail('incoming-request-plain.eml',
                              bcc: @spam_address.email)

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(0)
        deliveries.clear
      end

      it "recognises a spam email address under the 'envelope-to' header" do
        receive_incoming_mail('incoming-request-plain.eml',
                              envelope_to: @spam_address.email)

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(0)
        deliveries.clear
      end
    end

    it "should send a notice to sender when a request is stopped
        fully for spam" do
      # mark request as anti-spam
      ir = info_requests(:fancy_dog_request)
      ir.allow_new_responses_from = 'nobody'
      ir.handle_rejected_responses = 'bounce'
      ir.save!

      # test what happens if something arrives
      expect(ir.incoming_messages.count).to eq(1) # in the fixture
      receive_incoming_mail('incoming-request-plain.eml',
                            to: ir.incoming_email)
      expect(ir.incoming_messages.count).to eq(1) # nothing should arrive

      # should be a message back to sender
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq(['geraldinequango@localhost'])
      expect(mail.multipart?).to eq(false)
      expect(mail.body).to include("marked to no longer receive responses")
      deliveries.clear
    end

    it "should return incoming mail to sender if not authority when a request is stopped for non-authority spam" do
      # mark request as anti-spam
      ir = info_requests(:fancy_dog_request)
      ir.allow_new_responses_from = 'authority_only'
      ir.handle_rejected_responses = 'bounce'
      ir.save!

      # Test what happens if something arrives from authority domain
      # (@localhost)
      expect(ir.incoming_messages.count).to eq(1) # in the fixture
      receive_incoming_mail('incoming-request-plain.eml',
                            to: ir.incoming_email,
                            from: "Geraldine <geraldinequango@localhost>")
      expect(ir.incoming_messages.count).to eq(2) # one more arrives

      # ... should get "responses arrived" message for original requester
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      # to the user who sent fancy_dog_request
      expect(mail.to).to eq(['bob@localhost'])
      deliveries.clear

      # Test what happens if something arrives from another domain
      expect(ir.incoming_messages.count).to eq(2) # in fixture and above
      receive_incoming_mail('incoming-request-plain.eml',
                            to: ir.incoming_email,
                            from: "dummy-address@dummy.localhost")
      expect(ir.incoming_messages.count).to eq(2) # nothing should arrive

      # ... should be a bounce message back to sender
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq(['dummy-address@dummy.localhost'])
      deliveries.clear
    end

    it "discards rejected responses with a malformed From: when set to bounce" do
      ir = info_requests(:fancy_dog_request)
      ir.allow_new_responses_from = 'nobody'
      ir.handle_rejected_responses = 'bounce'
      ir.save!
      expect(ir.incoming_messages.count).to eq(1)

      receive_incoming_mail('incoming-request-plain.eml',
                            to: ir.incoming_email,
                            from: "")
      expect(ir.incoming_messages.count).to eq(1)

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
      deliveries.clear
    end

    it "should send all new responses to holding pen if a request is marked to do so" do
      # mark request as anti-spam
      ir = info_requests(:fancy_dog_request)
      ir.allow_new_responses_from = 'nobody'
      ir.handle_rejected_responses = 'holding_pen'
      ir.save!

      # test what happens if something arrives
      ir = info_requests(:fancy_dog_request)
      expect(ir.incoming_messages.count).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(0)
      receive_incoming_mail('incoming-request-plain.eml',
                            to: ir.incoming_email)
      expect(ir.incoming_messages.count).to eq(1)

      # arrives in holding pen
      expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(1)
      last_event = InfoRequest.holding_pen_request.info_request_events.last
      expect(last_event.params[:rejected_reason]).
        to match(/allow new responses from nobody/)

      # should be a message to admin regarding holding pen
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq([AlaveteliConfiguration.contact_email])
      deliveries.clear
    end

    it "should destroy the messages sent to a request if marked to do so" do
      ActionMailer::Base.deliveries.clear
      # mark request as anti-spam
      ir = info_requests(:fancy_dog_request)
      ir.allow_new_responses_from = 'nobody'
      ir.handle_rejected_responses = 'blackhole'
      ir.save!

      # test what happens if something arrives - should be nothing
      ir = info_requests(:fancy_dog_request)
      expect(ir.incoming_messages.count).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(0)
      receive_incoming_mail('incoming-request-plain.eml',
                            to: ir.incoming_email)
      expect(ir.incoming_messages.count).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(0)

      # should be no messages to anyone
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
    end
  end
end
