# == Schema Information
#
# Table name: raw_emails
#
#  id                :integer          not null, primary key
#  created_at        :datetime
#  updated_at        :datetime
#  from_email        :text
#  from_email_domain :text
#  from_name         :text
#  message_id        :text
#  sent_at           :datetime
#  subject           :text
#  valid_to_reply_to :boolean
#

require 'spec_helper'

RSpec.describe RawEmail do
  def roundtrip_data(raw_email, data)
    raw_email.data = data
    raw_email.save!
    raw_email.reload
    raw_email.data
  end

  describe '#valid_to_reply_to?' do
    subject { raw_email.valid_to_reply_to? }
    let(:raw_email) { RawEmail.new }

    before do
      allow(ReplyToAddressValidator).to receive(:valid?).and_return(true)
    end

    it 'returns true if from email is valid' do
      is_expected.to eq true
    end

    it "returns false an empty return-path is bad" do
      allow(raw_email).to receive(:empty_return_path?).and_return(true)
      is_expected.to eq false
    end

    it "returns false if auto-submitted keyword is bad" do
      allow(raw_email).to receive(:auto_submitted?).and_return(true)
      is_expected.to eq false
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
        test_real('incoming-request-plain.eml', true)
      end

      it "should not allow a reply to emails with empty return-paths" do
        test_real('empty-return-path.eml', false)
      end

      it "should not allow a reply to emails with autoresponse headers" do
        test_real('autoresponse-header.eml', false)
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
    let(:raw_email) { FactoryBot.create(:incoming_message).raw_email }

    it 'roundtrips data unchanged' do
      data = roundtrip_data(raw_email, "Hello, world!")
      expect(data).to eq("Hello, world!")
    end

    it 'returns an unchanged binary string with a valid encoding if the data is non-ascii and non-utf-8' do
      data = roundtrip_data(raw_email, "\xA0")

      expect(data.encoding.to_s).to eq('ASCII-8BIT')
      expect(data.valid_encoding?).to be true
      data = data.force_encoding('UTF-8')
      expect(data).to eq("\xA0")
    end
  end

  describe '#data_as_text' do
    it 'returns a utf-8 string with a valid encoding if the data is non-ascii and non-utf8' do
      raw_email = FactoryBot.create(:incoming_message).raw_email
      roundtrip_data(raw_email, "\xA0ccc")
      data_as_text = raw_email.data_as_text
      expect(data_as_text).to eq("ccc")
      expect(data_as_text.encoding.to_s).to eq('UTF-8')
      expect(data_as_text.valid_encoding?).to be true
    end
  end

  describe '#from_email_domain' do
    subject { raw_email.from_email_domain }

    let(:raw_email) do
      mail =
        get_fixture_mail('incoming-request-plain.eml', nil, 'b@example.net')
      raw_email = FactoryBot.create(:raw_email)
      FactoryBot.create(:incoming_message, raw_email: raw_email)
      raw_email.update!(data: mail)
      raw_email
    end

    it { is_expected.to eq('example.net') }
  end

  describe '#storage_key' do
    let(:raw_email) { FactoryBot.create(:raw_email, :with_file) }

    context 'when file is attached' do
      it 'returns the blob key' do
        expect(raw_email.file).to be_attached
        storage_key = raw_email.storage_key
        expect(storage_key).to eq(raw_email.file.blob.key)
      end
    end

    context 'when file is not attached' do
      let(:raw_email) { FactoryBot.create(:raw_email) }

      it 'returns nil' do
        expect(raw_email.storage_key).to be_nil
      end
    end
  end
end
