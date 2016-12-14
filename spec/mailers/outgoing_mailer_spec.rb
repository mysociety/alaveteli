# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OutgoingMailer, " when working out follow up names and addresses" do

  before do
    @info_request = mock_model(InfoRequest,
                               :recipient_name_and_email => 'test <test@example.com>',
                               :recipient_email => 'test@example.com')
    allow(@info_request).to receive_message_chain(:public_body, :name).and_return("Test Authority")
    @incoming_message = mock_model(IncomingMessage,
                                   :from_email => 'specific@example.com',
                                   :safe_mail_from => 'Specific Person')
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
      allow(@incoming_message).to receive(:safe_mail_from).and_return(nil)
      expect(OutgoingMailer.name_for_followup(@info_request, @incoming_message)).to eq('Test Authority')
    end

  end

end

describe OutgoingMailer, "when working out follow up subjects" do

  before(:each) do
    load_raw_emails_data
  end

  it "should prefix the title with 'Freedom of Information request -' for initial requests" do
    ir = info_requests(:fancy_dog_request)
    im = ir.incoming_messages[0]

    expect(ir.email_subject_request(:html => false)).to eq("Freedom of Information request - Why do you have & such a fancy dog?")
  end

  it "should use 'Re:' and inital request subject for followups which aren't replies to particular messages" do
    ir = info_requests(:fancy_dog_request)
    om = outgoing_messages(:useless_outgoing_message)

    expect(OutgoingMailer.subject_for_followup(ir, om, :html => false)).to eq("Re: Freedom of Information request - Why do you have & such a fancy dog?")
  end

  it "should prefix with Re: the subject of the message being replied to" do
    ir = info_requests(:fancy_dog_request)
    im = ir.incoming_messages[0]
    om = outgoing_messages(:useless_outgoing_message)
    om.incoming_message_followup = im

    expect(OutgoingMailer.subject_for_followup(ir, om, :html => false)).to eq("Re: Geraldine FOI Code AZXB421")
  end

  it "should not add Re: prefix if there already is such a prefix" do
    ir = info_requests(:fancy_dog_request)
    im = ir.incoming_messages[0]
    om = outgoing_messages(:useless_outgoing_message)
    om.incoming_message_followup = im

    im.raw_email.data = im.raw_email.data.sub("Subject: Geraldine FOI Code AZXB421", "Subject: Re: Geraldine FOI Code AZXB421")
    expect(OutgoingMailer.subject_for_followup(ir, om, :html => false)).to eq("Re: Geraldine FOI Code AZXB421")
  end

  it "should not add Re: prefix if there already is a lower case re: prefix" do
    ir = info_requests(:fancy_dog_request)
    im = ir.incoming_messages[0]
    om = outgoing_messages(:useless_outgoing_message)
    om.incoming_message_followup = im

    im.raw_email.data = im.raw_email.data.sub("Subject: Geraldine FOI Code AZXB421", "Subject: re: Geraldine FOI Code AZXB421")
    im.parse_raw_email! true

    expect(OutgoingMailer.subject_for_followup(ir, om, :html => false)).to eq("re: Geraldine FOI Code AZXB421")
  end

  it "should use 'Re:' and initial request subject when replying to failed delivery notifications" do
    ir = info_requests(:fancy_dog_request)
    im = ir.incoming_messages[0]
    om = outgoing_messages(:useless_outgoing_message)
    om.incoming_message_followup = im

    im.raw_email.data = im.raw_email.data.sub("foiperson@localhost", "postmaster@localhost")
    im.raw_email.data = im.raw_email.data.sub("Subject: Geraldine FOI Code AZXB421", "Subject: Delivery Failed")
    im.parse_raw_email! true

    expect(OutgoingMailer.subject_for_followup(ir, om, :html => false)).to eq("Re: Freedom of Information request - Why do you have & such a fancy dog?")
  end

  context "dealing with an internal review" do

    it "prefixes the subject of the message with 'Internal review of " \
          "Freedom of Information request'" do
      request = FactoryGirl.create(:info_request_with_internal_review_request,
                                   :title => "Test")
      expect(OutgoingMailer.subject_for_followup(
        request,
        request.outgoing_messages.last)).
          to eq("Internal review of Freedom of Information request - Test")
    end

    it "does not add HTMLEntities to the subject of the message" do
      request = FactoryGirl.create(:info_request_with_internal_review_request,
                                   :title => "Apostrophe's Test")
      expect(OutgoingMailer.subject_for_followup(
        request,
        request.outgoing_messages.last)).
          to eq("Internal review of Freedom of Information request - " \
                "Apostrophe's Test")
    end

  end
end
