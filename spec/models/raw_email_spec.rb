# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: raw_emails
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  updated_at :datetime
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RawEmail do

  def roundtrip_data(raw_email, data)
    raw_email.data = data
    raw_email.save!
    raw_email.reload
    raw_email.data
  end

  describe '#valid_to_reply_to?' do
    def test_email(result, email, empty_return_path, autosubmitted = nil)
      stubs = { :from_email => email,
                :empty_return_path? => empty_return_path,
                :auto_submitted? => autosubmitted }
      raw_email = RawEmail.new
      stubs.each do |method, value|
        allow(raw_email).to receive(method).and_return(value)
      end
      expect(raw_email.valid_to_reply_to?).to eq(result)
    end

    it "says a valid email is fine" do
      test_email(true, "team@mysociety.org", false)
    end

    it "says postmaster email is bad" do
      test_email(false, "postmaster@mysociety.org", false)
    end

    it "says Mailer-Daemon email is bad" do
      test_email(false, "Mailer-Daemon@mysociety.org", false)
    end

    it "says case mangled MaIler-DaemOn email is bad" do
      test_email(false, "MaIler-DaemOn@mysociety.org", false)
    end

    it "says Auto_Reply email is bad" do
      test_email(false, "Auto_Reply@mysociety.org", false)
    end

    it "says DoNotReply email is bad" do
      test_email(false, "DoNotReply@tube.tfl.gov.uk", false)
    end

    it "says no reply email is bad" do
      test_email(false, "noreply@tube.tfl.gov.uk", false)
      test_email(false, "no.reply@tube.tfl.gov.uk", false)
      test_email(false, "no-reply@tube.tfl.gov.uk", false)
    end

    it "says a filled-out return-path is fine" do
      test_email(true, "team@mysociety.org", false)
    end

    it "says an empty return-path is bad" do
      test_email(false, "team@mysociety.org", true)
    end

    it "says an auto-submitted keyword is bad" do
      test_email(false, "team@mysociety.org", false, "auto-replied")
    end

    it 'returns true if the full email is not included in the invalid reply addresses' do
      ReplyToAddressValidator.invalid_reply_addresses = %w(a@example.com)

      test_email(true, 'b@example.com', false)

      ReplyToAddressValidator.invalid_reply_addresses =
        ReplyToAddressValidator::DEFAULT_INVALID_REPLY_ADDRESSES
    end

    it 'returns false if the full email is included in the invalid reply addresses' do
      ReplyToAddressValidator.invalid_reply_addresses = %w(a@example.com)

      test_email(false, 'a@example.com', false)

      ReplyToAddressValidator.invalid_reply_addresses =
        ReplyToAddressValidator::DEFAULT_INVALID_REPLY_ADDRESSES
    end

    context 'checking validity to reply to with real emails' do
      def test_real(fixture_file, expected)
        mail = get_fixture_mail(fixture_file, 'a@example.com', 'b@example.net')
        raw_email = FactoryBot.create(:raw_email)
        FactoryBot.create(:incoming_message, raw_email: raw_email)
        raw_email.update!(data: mail)
        expect(raw_email.valid_to_reply_to?).to eq(expected)
      end

      it "should allow a reply to plain emails" do
        test_real('incoming-request-plain.email', true)
      end

      it "should not allow a reply to emails with empty return-paths" do
        test_real('empty-return-path.email', false)
      end

      it "should not allow a reply to emails with autoresponse headers" do
        test_real('autoresponse-header.email', false)
      end
    end
  end

  describe '#mail' do
    let(:raw_email) { FactoryBot.create(:incoming_message).raw_email }
    let(:mock_mail) { double }

    before do
      allow(raw_email).to receive(:mail!).and_return(mock_mail)
    end

    it 'parses the raw email data in to a structured mail object' do
      expect(raw_email.mail).to eq(mock_mail)
    end

    it 'caches the Mail object' do
      initial = raw_email.mail
      allow(raw_email).to receive(:mail!).and_return(double('updated'))
      expect(raw_email.mail).to eq(initial)
    end

  end

  describe '#mail!' do
    let(:data) do
      <<-EOF.strip_heredoc
      From: mikel@test.lindsaar.net
      To: you@test.lindsaar.net
      Subject: This is a test email

      This is the body
      EOF
    end

    let(:raw_email) { FactoryBot.create(:incoming_message).raw_email }
    let(:mock_mail) { Mail.new(data) }

    before do
      allow(MailHandler).to receive(:mail_from_raw_email).and_return(mock_mail)
    end

    it 'parses the raw email data in to a structured mail object' do
      expect(raw_email.mail!).to eq(mock_mail)
    end

    it 'updates the cache of the Mail object' do
      # Store a cached Mail
      initial = raw_email.mail

      # Call mail! again to get a fresh cache
      updated = double('updated')
      allow(MailHandler).to receive(:mail_from_raw_email).and_return(updated)
      raw_email.mail!

      # Now when we call the safe mail, we should get the last cached
      # version, _not_ the initial cache
      expect(raw_email.mail).to eq(updated)
    end

  end

  describe '#data' do

    it 'roundtrips data unchanged' do
      raw_email = FactoryBot.create(:incoming_message).raw_email
      data = roundtrip_data(raw_email, "Hello, world!")
      expect(data).to eq("Hello, world!")
    end

    it 'returns an unchanged binary string with a valid encoding if the data is non-ascii and non-utf-8' do
      raw_email = FactoryBot.create(:incoming_message).raw_email
      data = roundtrip_data(raw_email, "\xA0")

      if data.respond_to?(:encoding)
        expect(data.encoding.to_s).to eq('ASCII-8BIT')
        expect(data.valid_encoding?).to be true
        data = data.force_encoding('UTF-8')
      end
      expect(data).to eq("\xA0")
    end

  end

  describe '#data_as_text' do

    it 'returns a utf-8 string with a valid encoding if the data is non-ascii and non-utf8' do
      raw_email = FactoryBot.create(:incoming_message).raw_email
      roundtrip_data(raw_email, "\xA0ccc")
      data_as_text = raw_email.data_as_text
      expect(data_as_text).to eq("ccc")
      if data_as_text.respond_to?(:encoding)
        expect(data_as_text.encoding.to_s).to eq('UTF-8')
        expect(data_as_text.valid_encoding?).to be true
      end
    end

  end

  describe '#destroy_file_representation!' do

    let(:raw_email) { FactoryBot.create(:incoming_message).raw_email }

    it 'should delete the directory' do
      raw_email.destroy_file_representation!
      expect(File.exist?(raw_email.filepath)).to eq(false)
    end

    it 'should only delete the directory if it exists' do
      expect(File).to receive(:delete).once.and_call_original
      raw_email.destroy_file_representation!
      expect { raw_email.destroy_file_representation! }.not_to raise_error
    end

  end

end
