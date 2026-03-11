# == Schema Information
#
# Table name: raw_emails
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  erased_at  :datetime
#

require 'spec_helper'

RSpec.describe RawEmail do
  def roundtrip_data(raw_email, data)
    raw_email.data = data
    raw_email.save!
    raw_email.reload
    raw_email.data
  end

  describe '#expire' do
    let(:incoming_message) { FactoryBot.create(:incoming_message) }
    let(:raw_email) { incoming_message.raw_email }

    it 'delegates to info_request' do
      expect(raw_email.info_request).to receive(:expire)
      raw_email.expire
    end
  end

  describe '#log_event' do
    let(:incoming_message) { FactoryBot.create(:incoming_message) }
    let(:raw_email) { incoming_message.raw_email }

    it 'delegates to info_request' do
      expect(raw_email.info_request).to receive(:log_event).with('edit')
      raw_email.log_event('edit')
    end
  end

  describe '#lock_all_attachments' do
    let(:incoming_message) { FactoryBot.create(:incoming_message) }
    let(:raw_email) { incoming_message.raw_email }

    it 'delegates to incoming_message' do
      expect(raw_email.incoming_message).to receive(:lock_all_attachments)
      raw_email.lock_all_attachments
    end
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
    let(:inbound_email) do
      <<-EOF.strip_heredoc
      From: mikel@test.lindsaar.net
      To: you@test.lindsaar.net
      Subject: This is a test email

      This is the body
      EOF
    end

    let(:raw_email) { FactoryBot.create(:incoming_message).raw_email }
    let(:mock_mail) { Mail.new(inbound_email) }

    before do
      allow(MailHandler).to receive(:mail_from_string).and_return(mock_mail)
    end

    it 'parses the raw email data in to a structured mail object' do
      expect(raw_email.mail!).to eq(mock_mail)
    end

    it 'updates the cache of the Mail object' do
      # Store a cached Mail
      initial = raw_email.mail

      # Call mail! again to get a fresh cache
      updated = double('updated')
      allow(MailHandler).to receive(:mail_from_string).and_return(updated)
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
    subject { raw_email.data_as_text }

    let(:raw_email) do
      raw_email = FactoryBot.create(:incoming_message).raw_email
      roundtrip_data(raw_email, "\xA0ccc")
      raw_email
    end

    it 'returns a utf-8 string with a valid encoding if the data is non-ascii and non-utf8' do
      expect(subject).to eq("ccc")
      expect(subject.encoding.to_s).to eq('UTF-8')
      expect(subject.valid_encoding?).to be true
    end

    context 'when erased' do
      before do
        raw_email.erase(
          editor: FactoryBot.create(:admin_user),
          reason: 'PII'
        )
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#erasable?' do
    subject { raw_email.erasable? }

    let(:raw_email) { FactoryBot.build(:raw_email) }

    context 'when all attachments are masked' do
      before do
        allow(raw_email).to receive(:all_attachments_masked?).and_return(true)
      end

      it { is_expected.to eq(true) }
    end

    context 'when not all attachments are masked' do
      before do
        allow(raw_email).to receive(:all_attachments_masked?).and_return(false)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#erased?' do
    subject { raw_email.erased? }

    let(:raw_email) do
      request = FactoryBot.create(:info_request)
      message = FactoryBot.create(:incoming_message, info_request: request)
      message.raw_email = FactoryBot.create(:raw_email, :with_file)
      message.save!
      message.raw_email
    end

    it { is_expected.to eq(false) }

    context 'when erased' do
      before do
        raw_email.erase(
          editor: FactoryBot.create(:admin_user),
          reason: 'PII'
        )
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '#erase' do
    subject { raw_email.erase(editor: editor, reason: reason) }

    let(:raw_email) do
      request = FactoryBot.create(:info_request)
      message = FactoryBot.create(:incoming_message, info_request: request)
      message.raw_email = FactoryBot.create(:raw_email, :with_file)
      message.save!
      message.raw_email
    end

    let(:editor) { FactoryBot.create(:admin_user) }
    let(:reason) { 'Removing PII' }

    it 'locks all attachments' do
      expect(raw_email.incoming_message).to receive(:lock_all_attachments).with(
        editor: editor,
        reason: 'RawEmail#erase',
        raw_email: raw_email
      )
      subject
    end

    it 'purges later' do
      expect { subject }.to have_enqueued_job(ActiveStorage::PurgeJob)
    end

    it 'purges the attached file' do
      subject
      expect(raw_email.reload.file).not_to be_attached
    end

    it 'touches erased_at' do
      expect { subject }.to change(raw_email, :erased_at).from(nil)
      expect(raw_email.erased_at).to be_a(Time)
    end

    def last_event
      raw_email.info_request.info_request_events.last
    end

    it 'logs an event on the associated info_request' do
      expect { subject }.to change { last_event }
      expect(last_event.event_type).to eq('erase_raw_email')
    end

    it 'expires the associated info_request' do
      expect(raw_email.info_request).to receive(:expire)
      subject
    end

    it { is_expected.to eq(true) }

    context 'when already erased' do
      before { allow(raw_email).to receive(:erased?).and_return(true) }

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::AlreadyErasedError)
      end
    end

    context 'when there are unmasked attachments' do
      before do
        allow(raw_email).to receive(:all_attachments_masked?).and_return(false)
      end

      it 'raises an error' do
        expect { subject }.
          to raise_error(described_class::UnmaskedAttachmentsError)
      end
    end

    context 'when an attachment cannot be locked' do
      before do
        expect(raw_email).to receive(:lock_all_attachments).and_return(false)
      end

      it 'does not erase the file' do
        subject
        expect(raw_email.reload).not_to be_erased
      end

      it { is_expected.to eq(false) }
    end

    context 'when an event cannot be logged' do
      before do
        expect(raw_email).to receive(:log_event).and_return(false)
      end

      it 'does not erase the file' do
        subject
        perform_enqueued_jobs
        expect(raw_email.reload).not_to be_erased
      end

      it { is_expected.to eq(false) }
    end

    context 'when the file cannot be purged' do
      before do
        expect_any_instance_of(ActiveStorage::Attached::One).
          to receive(:purge_later).and_raise(ActiveStorage::FileNotFoundError)
      end

      it 'does not erase the file' do
        subject
        perform_enqueued_jobs
        expect(raw_email.reload).not_to be_erased
      end

      it { is_expected.to eq(false) }
    end

    context 'when the record cannot be touched' do
      before do
        expect(raw_email).
          to receive(:touch).and_raise(ActiveRecord::ActiveRecordError)
      end

      it 'does not erase the file' do
        subject
        expect(raw_email.reload).not_to be_erased
      end

      it { is_expected.to eq(false) }
    end

    context 'when the info request cannot be expired' do
      before do
        expect(raw_email).to receive(:expire).and_raise(StandardError)
      end

      it 'does not erase the file' do
        subject
        expect(raw_email.reload).not_to be_erased
      end

      it { is_expected.to eq(false) }
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
