require 'spec_helper'

RSpec.describe OutgoingMailer, " when working out follow up names and addresses" do
  before do
    @info_request = mock_model(InfoRequest,
                               recipient_name_and_email: 'test <test@example.com>',
                               recipient_email: 'test@example.com')
    allow(@info_request).to receive_message_chain(:public_body, :name).and_return("Test Authority")
    @incoming_message = mock_model(IncomingMessage,
                                   from_email: 'specific@example.com',
                                   safe_from_name: 'Specific Person')
  end

  describe 'if there is no incoming message being replied to' do
    it 'should return the name and email address of the public body' do
      expect(OutgoingMailer.name_and_email_for_followup(@info_request, nil)).to eq('test <test@example.com>')
      expect(OutgoingMailer.name_for_followup(@info_request, nil)).to eq('Test Authority')
      expect(OutgoingMailer.email_for_followup(@info_request, nil)).to eq('test@example.com')
    end
  end

  describe 'if the incoming message being replied to is not valid to reply to' do
    before do
      allow(@incoming_message).to receive(:valid_to_reply_to?).and_return(false)
    end

    it 'should return the safe name and email address of the public body' do
      expect(OutgoingMailer.name_and_email_for_followup(@info_request, @incoming_message)).to eq('test <test@example.com>')
      expect(OutgoingMailer.name_for_followup(@info_request, @incoming_message)).to eq('Test Authority')
      expect(OutgoingMailer.email_for_followup(@info_request, @incoming_message)).to eq('test@example.com')
    end
  end

  describe 'if the incoming message is valid to reply to' do
    before do
      allow(@incoming_message).to receive(:valid_to_reply_to?).and_return(true)
    end

    it 'should return the name and email address from the incoming message' do
      expect(OutgoingMailer.name_and_email_for_followup(@info_request, @incoming_message)).to eq('Specific Person <specific@example.com>')
      expect(OutgoingMailer.name_for_followup(@info_request, @incoming_message)).to eq('Specific Person')
      expect(OutgoingMailer.email_for_followup(@info_request, @incoming_message)).to eq('specific@example.com')
    end

    it 'should return the name of the public body if the incoming message does not have
            a safe name' do
      allow(@incoming_message).to receive(:safe_from_name).and_return(nil)
      expect(OutgoingMailer.name_for_followup(@info_request, @incoming_message)).to eq('Test Authority')
    end
  end
end

RSpec.describe OutgoingMailer, "when sending mail" do
  # String-composition rules (Re: prefixing, internal review, html
  # escaping, etc) are covered by spec/models/outgoing_message/subject_spec.rb
  # - these just check the real mailer actions deliver with the expected
  # subject header.
  describe '#initial_request' do
    it "uses the request title with the law prefixed" do
      ir = info_requests(:fancy_dog_request)
      om = outgoing_messages(:useless_outgoing_message)

      mail = OutgoingMailer.initial_request(ir, om)
      expect(mail.subject).
        to eq("Freedom of Information request - " \
              "Why do you have & such a fancy dog?")
    end
  end

  describe '#followup' do
    it "prefixes with Re: the subject of the message being replied to" do
      ir = info_requests(:fancy_dog_request)
      im = ir.incoming_messages[0]
      om = outgoing_messages(:useless_outgoing_message)
      om.message_type = 'followup'
      om.incoming_message_followup = im

      mail = OutgoingMailer.followup(ir, om, im)
      expect(mail.subject).to eq("Re: Geraldine FOI Code AZXB421")
    end

    context "dealing with an internal review" do
      it "prefixes the subject of the message with 'Internal review of " \
            "Freedom of Information request'" do
        request = FactoryBot.create(
          :info_request_with_internal_review_request, title: "Test"
        )
        om = request.outgoing_messages.last

        mail = OutgoingMailer.followup(
          request, om, om.incoming_message_followup
        )
        expect(mail.subject).
          to eq("Internal review of Freedom of Information request - Test")
      end
    end
  end
end
