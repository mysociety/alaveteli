# == Schema Information
#
# Table name: foi_attachments
#
#  id                    :integer          not null, primary key
#  content_type          :text
#  filename              :text
#  charset               :text
#  display_size          :text
#  url_part_number       :integer
#  within_rfc822_subject :text
#  incoming_message_id   :integer
#  hexdigest             :string(32)
#  created_at            :datetime
#  updated_at            :datetime
#  prominence            :string           default("normal")
#  prominence_reason     :text
#  masked_at             :datetime
#  locked                :boolean          default(FALSE)
#  replaced_at           :datetime
#  replaced_reason       :string
#  erased_at             :datetime
#

require 'spec_helper'
require 'models/concerns/message_prominence'

RSpec.describe FoiAttachment do
  include ActiveJob::TestHelper

  it_behaves_like 'concerns/message_prominence', :body_text

  describe '.binary' do
    subject { described_class.binary }

    before do
      FactoryBot.create(:body_text)
      FactoryBot.create(:html_attachment)
    end

    let(:binary_attachments) do
      [FactoryBot.create(:pdf_attachment),
       FactoryBot.create(:rtf_attachment),
       FactoryBot.create(:jpeg_attachment),
       FactoryBot.create(:unknown_attachment)]
    end

    it { is_expected.to match_array(binary_attachments) }
  end

  describe '.locked' do
    subject { described_class.locked }

    let!(:locked_attachment) { FactoryBot.create(:body_text, :locked) }
    let!(:unlocked_attachment) { FactoryBot.create(:body_text, :unlocked) }

    it { is_expected.to include(locked_attachment) }
    it { is_expected.to_not include(unlocked_attachment) }
  end

  describe '.unlocked' do
    subject { described_class.unlocked }

    let!(:locked_attachment) { FactoryBot.create(:body_text, :locked) }
    let!(:unlocked_attachment) { FactoryBot.create(:body_text, :unlocked) }

    it { is_expected.to_not include(locked_attachment) }
    it { is_expected.to include(unlocked_attachment) }
  end

  describe '.erased' do
    subject { described_class.erased }

    let!(:erased_attachment) { FactoryBot.create(:body_text, :erased) }
    let!(:non_erased_attachment) { FactoryBot.create(:body_text) }

    it { is_expected.to include(erased_attachment) }
    it { is_expected.to_not include(non_erased_attachment) }
  end

  describe '.cached_urls' do
    it 'includes the correct paths' do
      att = FactoryBot.create(:jpeg_attachment)
      im = FactoryBot.create(:plain_incoming_message)
      att.incoming_message = im
      request_path = "/request/" + att.info_request.url_title
      expect(att.cached_urls).to eq([request_path])
    end
  end

  describe 'validation: must_be_unlockable_to_unlock' do
    let(:foi_attachment) do
      attachment = FactoryBot.create(:body_text, :locked)
      attachment.incoming_message = FactoryBot.create(:plain_incoming_message)
      attachment
    end

    # Attempt to unlock
    before { foi_attachment.locked = false }

    context 'when attempting to unlock an attachment that is not unlockable' do
      before do
        allow(foi_attachment).to receive(:unlockable?).and_return(false)
        foi_attachment.valid?
      end

      it 'is invalid' do
        expect(foi_attachment).not_to be_valid
      end

      it 'adds an error' do
        msg = 'This attachment cannot be unlocked.'
        expect(foi_attachment.errors[:base]).to include(msg)
      end
    end
  end

  describe 'replacement attributes' do
    let(:foi_attachment) { FactoryBot.create(:body_text) }

    it 'has a replacement_file attribute' do
      expect(foi_attachment).to respond_to(:replacement_file)
      expect(foi_attachment).to respond_to(:replacement_file=)
    end

    it 'has a replacement_body attribute' do
      expect(foi_attachment).to respond_to(:replacement_body)
      expect(foi_attachment).to respond_to(:replacement_body=)
    end
  end

  describe '#body=' do
    it "sets the body" do
      attachment = FoiAttachment.new
      attachment.body = "baz"
      expect(attachment.body).to eq("baz")
    end

    it "sets the size" do
      attachment = FoiAttachment.new
      attachment.body = "baz"
      expect(attachment.body).to eq("baz")
      expect(attachment.display_size).to eq("0K")
    end

    it "reparses the body if it disappears" do
      im = incoming_messages(:useless_incoming_message)
      im.extract_attachments!
      main = im.get_main_body_text_part
      orig_body = main.body
      main.delete_cached_file!
      expect {
        im.get_main_body_text_part.body
      }.not_to raise_error
      main.delete_cached_file!
      main = im.get_main_body_text_part
      expect(main.body).to eq(orig_body)
    end

    it 'can parse raw email and read attachment inside DB transaction' do
      im = FactoryBot.create(:plain_incoming_message)
      FoiAttachment.transaction do
        expect { im.get_text_for_indexing_full }.to_not raise_error
        main_part = im.get_main_body_text_part
        expect(main_part.body).to match(/That's so totally a rubbish question/)
      end
    end

    it 'does not update hexdigest if already present' do
      attachment = FoiAttachment.new(hexdigest: 'ABC')
      expect { attachment.body = 'foo' }.to_not change { attachment.hexdigest }
    end

    it 'allow calls to #body to be made before save' do
      attachment = FactoryBot.build(:foi_attachment, :unmasked)
      blob = attachment.file.blob

      expect {
        attachment.body
        attachment.save!
      }.to change {
        ActiveStorage::Blob.services.fetch(blob.service_name).exist?(blob.key)
      }.from(false).to(true)
    end

    it 'does not reset existing blob key' do
      attachment = FactoryBot.create(
        :foi_attachment, :unmasked, body: 'unmasked'
      )

      expect { attachment.update(body: 'masked', masked_at: Time.now) }.
        to_not change { attachment.file_blob.key }
    end

    it 'does not reset existing blob metadata' do
      attachment = FactoryBot.create(
        :foi_attachment, :unmasked, body: 'unmasked'
      )

      expect { attachment.update(body: 'masked', masked_at: Time.now) }.
        to_not change { attachment.file_blob.metadata }
    end

    it 'persists changes to existing blob checksum' do
      attachment = FactoryBot.create(
        :foi_attachment, :unmasked, body: 'unmasked'
      )

      expect { attachment.update(body: 'masked', masked_at: Time.now) }.
        to change { attachment.file_blob.checksum }
      expect(attachment.file_blob.changed?).to eq false
    end
  end

  describe '#body' do
    context 'when erased' do
      let(:foi_attachment) { FactoryBot.create(:body_text, :erased) }

      it 'raises MissingAttachment error' do
        expect { foi_attachment.body }.
          to raise_error(FoiAttachment::MissingAttachment, /erased/)
      end
    end

    context 'when locked' do
      let(:foi_attachment) { FactoryBot.create(:body_text, :locked) }
      let(:locked_content) { "Test locked content" }

      before do
        allow(foi_attachment.file).to receive(:download).
          and_return(locked_content)
      end

      it 'returns the locked content from the active storage file' do
        expect(foi_attachment.body).to eq locked_content
      end
    end

    context 'when locked but stored attachment is missing' do
      let(:foi_attachment) { FactoryBot.create(:body_text, :locked) }

      before do
        allow(foi_attachment.file).
          to receive(:download).and_raise(ActiveStorage::FileNotFoundError)
      end

      it 'does not run FoiAttachmentMaskJob and raise error' do
        expect(FoiAttachmentMaskJob).to_not receive(:perform_now)
        expect { foi_attachment.body }.
          to raise_error(ActiveStorage::FileNotFoundError)
      end
    end

    context 'when masked' do
      let(:foi_attachment) { FactoryBot.create(:body_text) }

      it 'returns a binary encoded string when newly created' do
        expect(foi_attachment.body.encoding.to_s).to eq('ASCII-8BIT')
      end

      it 'returns a binary encoded string when saved' do
        foi_attachment_2 = FoiAttachment.find(foi_attachment.id)
        expect(foi_attachment_2.body.encoding.to_s).to eq('ASCII-8BIT')
      end
    end

    context 'when masked but stored attachment is missing' do
      let(:foi_attachment) { FactoryBot.create(:body_text) }

      before do
        allow(foi_attachment.file).
          to receive(:download).and_raise(ActiveStorage::FileNotFoundError)
      end

      it 'calls the FoiAttachmentMaskJob now and return the masked body' do
        expect(FoiAttachmentMaskJob).to receive(:perform_now).
          with(foi_attachment).
          and_invoke(-> (_) {
            # mock the job
            foi_attachment.update(body: 'maskedbody', masked_at: Time.zone.now)
          })

        expect(foi_attachment.body).to eq('maskedbody')
      end
    end

    context 'when unmasked and original attachment can be found' do
      let(:incoming_message) do
        FactoryBot.create(:incoming_message, foi_attachments_factories: [
          [:body_text, :unmasked]
        ])
      end
      let(:foi_attachment) { incoming_message.foi_attachments.last }

      it 'calls the FoiAttachmentMaskJob now and return the masked body' do
        expect(FoiAttachmentMaskJob).to receive(:perform_now).
          with(foi_attachment).
          and_invoke(-> (_) {
            # mock the job
            foi_attachment.update(body: 'maskedbody', masked_at: Time.zone.now)
          })

        expect(foi_attachment.body).to eq('maskedbody')
      end
    end

    context 'when unmasked and original attachment can not be found' do
      let(:incoming_message) do
        FactoryBot.create(:incoming_message, foi_attachments_factories: [
          [:body_text, :unmasked]
        ])
      end
      let(:foi_attachment) { incoming_message.foi_attachments.last }

      before do
        foi_attachment.update(hexdigest: '123')

        expect(FoiAttachmentMaskJob).to receive(:perform_now).
          with(foi_attachment).
          and_invoke(-> (_) {
            # mock the job
            incoming_message.parse_raw_email!
          })
      end

      it 'returns load_attachment_from_incoming_message.body' do
        allow(foi_attachment).to(
          receive(:load_attachment_from_incoming_message).and_return(
            double(body: 'thisisthenewtext')
          )
        )
        expect(foi_attachment.body).to eq('thisisthenewtext')
      end

      it 'raises MissingAttachment exception if attachment still can not be found' do
        allow(foi_attachment).to(
          receive(:load_attachment_from_incoming_message).and_return(nil)
        )
        expect { foi_attachment.body }.to raise_error(
          FoiAttachment::MissingAttachment
        )
      end
    end

    context 'when attachment has been destroy' do
      let(:foi_attachment) { FactoryBot.create(:foi_attachment) }

      before { foi_attachment.destroy }

      it 'returns load_attachment_from_incoming_message.body' do
        allow(foi_attachment).to(
          receive(:load_attachment_from_incoming_message).and_return(
            double(body: 'thisisthenewtext')
          )
        )
        expect(foi_attachment.body).to eq('thisisthenewtext')
      end
    end
  end

  describe '#body_as_text' do
    context 'when erased' do
      let(:foi_attachment) { FactoryBot.create(:body_text, :erased) }

      it 'raises MissingAttachment error' do
        expect { foi_attachment.body_as_text }.
          to raise_error(FoiAttachment::MissingAttachment, /erased/)
      end
    end

    it 'has a valid UTF-8 string when newly created' do
      foi_attachment = FactoryBot.create(:body_text)
      expect(foi_attachment.body_as_text.string.encoding.to_s).to eq('UTF-8')
      expect(foi_attachment.body_as_text.string.valid_encoding?).to be true
    end

    it 'has a valid UTF-8 string when saved' do
      foi_attachment = FactoryBot.create(:body_text)
      foi_attachment = FoiAttachment.find(foi_attachment.id)
      expect(foi_attachment.body_as_text.string.encoding.to_s).to eq('UTF-8')
      expect(foi_attachment.body_as_text.string.valid_encoding?).to be true
    end

    it 'has a true scrubbed? value if the body has been coerced to valid UTF-8' do
      foi_attachment = FactoryBot.create(:body_text)
      foi_attachment.body = "\x0FX\x1C\x8F\xA4\xCF\xF6\x8C\x9D\xA7\x06\xD9\xF7\x90lo"
      expect(foi_attachment.body_as_text.scrubbed?).to be true
    end

    it 'has a false scrubbed? value if the body has not been coerced to valid UTF-8' do
      foi_attachment = FactoryBot.create(:body_text)
      foi_attachment.body = "κόσμε"
      expect(foi_attachment.body_as_text.scrubbed?).to be false
    end
  end

  describe '#default_body' do
    context 'when erased' do
      let(:foi_attachment) { FactoryBot.create(:body_text, :erased) }

      it 'raises MissingAttachment error' do
        expect { foi_attachment.default_body }.
          to raise_error(FoiAttachment::MissingAttachment, /erased/)
      end
    end

    it 'returns valid UTF-8 for a text attachment' do
      foi_attachment = FactoryBot.create(:body_text)
      expect(foi_attachment.default_body.encoding.to_s).to eq('UTF-8')
      expect(foi_attachment.default_body.valid_encoding?).to be true
    end

    it 'returns binary for a PDF attachment' do
      foi_attachment = FactoryBot.create(:pdf_attachment)
      expect(foi_attachment.default_body.encoding.to_s).to eq('ASCII-8BIT')
    end
  end

  describe '#unmasked_body' do
    let(:foi_attachment) { FactoryBot.create(:body_text) }
    subject(:unmasked_body) { foi_attachment.unmasked_body }

    before do
      allow(foi_attachment).to receive(:raw_email).
        and_return(double(mail: Mail.new))
    end

    context 'when erased' do
      let(:foi_attachment) { FactoryBot.create(:body_text, :erased) }

      it 'raises MissingAttachment error' do
        expect { foi_attachment.unmasked_body }.
          to raise_error(FoiAttachment::MissingAttachment, /erased/)
      end
    end

    context 'when mail handler finds original attachment by hexdigest' do
      before do
        allow(MailHandler).to receive(:attachment_attributes_for_hexdigest).
          and_return(body: 'hereistheunmaskedtext')
      end

      it 'returns the attachment body from the raw email' do
        is_expected.to eq('hereistheunmaskedtext')
      end
    end

    context 'when able to find original attachment through other means' do
      before do
        allow(MailHandler).to receive(:attachment_body_for_hexdigest).
          and_raise(MailHandler::MismatchedAttachmentHexdigest)

        allow(MailHandler).to receive(
          :attempt_to_find_original_attachment_attributes
        ).and_return(hexdigest: 'ABC', body: 'hereistheunmaskedtext')
      end

      it 'updates the hexdigest' do
        expect { unmasked_body }.to change { foi_attachment.hexdigest }.
          to('ABC')
      end

      it 'returns the attachment body from the raw email' do
        is_expected.to eq('hereistheunmaskedtext')
      end
    end

    context 'when unable to find original attachment in storage' do
      before do
        allow(foi_attachment.file).
          to receive(:download).and_raise(ActiveStorage::FileNotFoundError)
      end

      it 'raises missing attachment exception' do
        expect { unmasked_body }.to raise_error(
          FoiAttachment::MissingAttachment,
          "attachment missing from storage (ID=#{foi_attachment.id})"
        )
      end
    end

    context 'when unable to find original attachment through other means' do
      before do
        allow(MailHandler).to receive(:attachment_body_for_hexdigest).
          and_raise(MailHandler::MismatchedAttachmentHexdigest)

        allow(MailHandler).to receive(
          :attempt_to_find_original_attachment_attributes
        ).and_return(nil)
      end

      it 'raises missing attachment exception' do
        expect { unmasked_body }.to raise_error(
          FoiAttachment::MissingAttachment,
          "attachment missing in raw email (ID=#{foi_attachment.id})"
        )
      end
    end
  end

  describe 'masked?' do
    let(:foi_attachment) do
      FoiAttachment.new(body: 'foo', masked_at: Time.zone.now)
    end

    subject { foi_attachment.masked? }

    it { is_expected.to eq(true) }

    context 'without file attached' do
      let(:foi_attachment) { FoiAttachment.new(masked_at: Time.zone.now) }
      it { is_expected.to eq(false) }
    end

    context 'without masked_at' do
      let(:foi_attachment) { FoiAttachment.new(body: 'foo') }
      it { is_expected.to eq(false) }
    end

    context 'when masked_at is in the future' do
      let(:foi_attachment) do
        FoiAttachment.new(body: 'foo', masked_at: Time.zone.now + 1.day)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#main_body_part?' do
    subject { attachment.main_body_part? }

    let(:message) { FactoryBot.build(:incoming_message, :with_pdf_attachment) }

    context 'when the attachment is the main body' do
      let(:attachment) { message.get_main_body_text_part }
      it { is_expected.to eq(true) }
    end

    context 'when the attachment is not the main body' do
      let(:attachment) { message.get_attachments_for_display.first }
      it { is_expected.to eq(false) }
    end
  end

  describe '#filename=' do
    it 'strips null bytes' do
      attachment = FactoryBot.build(:pdf_attachment)
      attachment.filename = "Tender Loving Care Trust (Europe).pdf\u0000"
      expect(attachment.filename).to eq('Tender Loving Care Trust (Europe).pdf')
    end
  end

  describe '#ensure_filename!' do
    it 'should create a filename for an instance with a blank filename' do
      attachment = FoiAttachment.new
      attachment.filename = ''
      attachment.ensure_filename!
      expect(attachment.filename).to eq('attachment.bin')
    end
  end

  describe '#has_body_as_html?' do
    context 'when erased' do
      let(:foi_attachment) { FactoryBot.create(:pdf_attachment, :erased) }

      it 'returns false' do
        expect(foi_attachment.has_body_as_html?).to be false
      end
    end

    it 'should be true for a pdf attachment' do
      expect(FactoryBot.build(:pdf_attachment).has_body_as_html?).to be true
    end

    it 'should be false for an html attachment' do
      expect(FactoryBot.build(:html_attachment).has_body_as_html?).to be false
    end
  end

  describe '#body_as_html' do
    context 'when erased' do
      let(:foi_attachment) { FactoryBot.create(:pdf_attachment, :erased) }

      it 'raises MissingAttachment error' do
        expect { foi_attachment.body_as_html }.
          to raise_error(FoiAttachment::MissingAttachment, /erased/)
      end
    end
  end

  describe '#name_of_content_type' do
    subject { foi_attachment.name_of_content_type }

    before do
      stub = { 'content/named' => 'Named content' }
      stub_const("#{described_class}::CONTENT_TYPE_NAMES", stub)
    end

    let(:foi_attachment) do
      FactoryBot.build(:foi_attachment, content_type: content_type)
    end

    context 'when the content_type has a name' do
      let(:content_type) { 'content/named' }
      it { is_expected.to eq('Named content') }
    end

    context 'when the content_type has no name' do
      let(:content_type) { 'content/unnamed' }
      it { is_expected.to be_nil }
    end
  end

  describe '#extra_note' do
    subject { foi_attachment.extra_note }

    context 'with a delivery status notification' do
      let(:foi_attachment) do
        FactoryBot.create(:delivery_status_notification_attachment)
      end

      let(:note) do
        'DSN: 4.4.0 Other or undefined network or routing status'
      end

      it { is_expected.to eq(note) }
    end

    context 'with any other content type' do
      let(:foi_attachment) { FactoryBot.build(:rtf_attachment) }
      it { is_expected.to be_nil }
    end
  end

  describe '#expire' do
    let(:incoming_message) { FactoryBot.create(:incoming_message) }
    let(:foi_attachment) { incoming_message.foi_attachments.first }

    it 'delegates to info_request' do
      expect(foi_attachment.info_request).to receive(:expire)
      foi_attachment.expire
    end
  end

  describe '#log_event' do
    let(:incoming_message) { FactoryBot.create(:incoming_message) }
    let(:foi_attachment) { incoming_message.foi_attachments.first }

    it 'delegates to info_request' do
      expect(foi_attachment.info_request).to receive(:log_event).with('edit')
      foi_attachment.log_event('edit')
    end
  end

  describe '#update_and_log_event' do
    let(:incoming_message) { FactoryBot.create(:incoming_message) }
    let(:info_request) { incoming_message.info_request }
    let(:foi_attachment) { incoming_message.foi_attachments.first }

    def last_event
      info_request.info_request_events.last
    end

    it 'updates and logs edit_attachment event' do
      expect do
        foi_attachment.update_and_log_event(prominence: 'hidden')
      end.to change { last_event }

      expect(last_event.event_type).to eq('edit_attachment')
    end

    it 'logs prominence and reason changes' do
      foi_attachment.update_and_log_event(
        prominence: 'hidden', prominence_reason: 'just because'
      )
      expect(last_event.params[:old_prominence]).to eq('normal')
      expect(last_event.params[:prominence]).to eq('hidden')
      expect(last_event.params[:old_prominence_reason]).to be_nil
      expect(last_event.params[:prominence_reason]).to eq('just because')
    end

    it 'logs locked changes' do
      foi_attachment.update_and_log_event(locked: true)
      expect(last_event.params[:old_locked]).to eq(false)
      expect(last_event.params[:locked]).to eq(true)
    end

    it 'logs replaced changes' do
      allow(foi_attachment).to receive(:replaced_at).
        and_return(Time.new(2025, 4, 10, 10, 30))
      foi_attachment.update_and_log_event(
        replacement_body: 'new body', replaced_reason: 'GDPR case'
      )
      expect(last_event.params[:old_locked]).to eq(false)
      expect(last_event.params[:locked]).to eq(true)
      expect(last_event.params[:replaced]).to eq(true)
      expect(last_event.params[:replaced_at]).
        to eq(Time.new(2025, 04, 10, 10, 30).as_json)
      expect(last_event.params[:replaced_reason]).to eq('GDPR case')
    end

    it 'logs additional event data' do
      foi_attachment.update_and_log_event(
        prominence: 'hidden', event: { editor: 'me' }
      )
      expect(last_event.params[:editor]).to eq('me')
    end

    it 'does not log event if update fails' do
      expect do
        foi_attachment.update_and_log_event(prominence: nil)
      end.to_not change { last_event }
    end
  end

  describe '#update_and_log_event!' do
    let(:incoming_message) { FactoryBot.create(:incoming_message) }
    let(:info_request) { incoming_message.info_request }
    let(:foi_attachment) { incoming_message.foi_attachments.first }

    def last_event
      info_request.info_request_events.last
    end

    it 'updates and logs edit_attachment event' do
      expect do
        foi_attachment.update_and_log_event!(prominence: 'hidden')
      end.to change { last_event }

      expect(last_event.event_type).to eq('edit_attachment')
    end

    it 'logs prominence and reason changes' do
      foi_attachment.update_and_log_event!(
        prominence: 'hidden', prominence_reason: 'just because'
      )
      expect(last_event.params[:old_prominence]).to eq('normal')
      expect(last_event.params[:prominence]).to eq('hidden')
      expect(last_event.params[:old_prominence_reason]).to be_nil
      expect(last_event.params[:prominence_reason]).to eq('just because')
    end

    it 'logs locked changes' do
      foi_attachment.update_and_log_event!(locked: true)
      expect(last_event.params[:old_locked]).to eq(false)
      expect(last_event.params[:locked]).to eq(true)
    end

    it 'logs replaced changes' do
      allow(foi_attachment).to receive(:replaced_at).
        and_return(Time.new(2025, 4, 10, 10, 30))
      foi_attachment.update_and_log_event!(
        replacement_body: 'new body', replaced_reason: 'GDPR case'
      )
      expect(last_event.params[:old_locked]).to eq(false)
      expect(last_event.params[:locked]).to eq(true)
      expect(last_event.params[:replaced]).to eq(true)
      expect(last_event.params[:replaced_at]).
        to eq(Time.new(2025, 04, 10, 10, 30).as_json)
      expect(last_event.params[:replaced_reason]).to eq('GDPR case')
    end

    it 'logs additional event data' do
      foi_attachment.update_and_log_event!(
        prominence: 'hidden', event: { editor: 'me' }
      )
      expect(last_event.params[:editor]).to eq('me')
    end

    it 'raises an exception if update fails' do
      expect do
        foi_attachment.update_and_log_event!(prominence: nil)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'does not log event if update fails' do
      expect do
        foi_attachment.update_and_log_event!(prominence: nil)
      rescue ActiveRecord::RecordInvalid
        # expected
      end.to_not change { last_event }
    end

    it 'raises an exception if logging fails' do
      allow(foi_attachment).to receive(:log_event).
        and_raise(ActiveRecord::RecordInvalid)

      expect do
        foi_attachment.update_and_log_event!(prominence: 'hidden')
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'rolls back update if logging fails' do
      allow(foi_attachment).to receive(:log_event).
        and_raise(ActiveRecord::RecordInvalid)

      expect do
        foi_attachment.update_and_log_event!(prominence: 'hidden')
      rescue ActiveRecord::RecordInvalid
        # expected
      end.to_not change { foi_attachment.reload.prominence }
    end
  end

  describe '#mask' do
    subject { attachment.mask }

    let(:info_request) { FactoryBot.create(:info_request_with_html_attachment) }
    let(:incoming_message) { info_request.incoming_messages.first }
    let(:attachment) { incoming_message.foi_attachments.last }

    before { rebuild_raw_emails(info_request) }

    it 'updates masked_at' do
      info_request.censor_rules.create!(
        text: 'dull', replacement: 'boring',
        last_edit_editor: 'unknown', last_edit_comment: 'none'
      )

      expect { subject }.to change { attachment.masked_at }.to(Time)
    end

    it 'sanitises HTML attachments' do
      # Nokogiri adds the meta tag; see
      # https://github.com/sparklemotion/nokogiri/issues/1008
      expected = <<-EOF.squish
      <!DOCTYPE html>
      <html>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        </head>
        <body>dull
        </body>
      </html>
      EOF

      subject
      expect(attachment.body.squish).to eq(expected)
    end

    it 'censors attachments downloaded directly' do
      info_request.censor_rules.create!(
        text: 'dull', replacement: 'Boy',
        last_edit_editor: 'unknown', last_edit_comment: 'none'
      )
      subject
      expect(attachment.body).to_not include 'dull'
      expect(attachment.body).to include 'Boy'
    end

    it 'censors with rules on the user (rather than the request)' do
      info_request.user.censor_rules.create!(
        text: 'dull', replacement: 'Mole',
        last_edit_editor: 'unknown', last_edit_comment: 'none'
      )
      subject
      expect(attachment.body).to_not include 'dull'
      expect(attachment.body).to include 'Mole'
    end

    it 'censors with rules on the public body (rather than the request)' do
      info_request.public_body.censor_rules.create!(
        text: 'dull', replacement: 'Fox',
        last_edit_editor: 'unknown', last_edit_comment: 'none'
      )
      subject
      expect(attachment.body).to_not include 'dull'
      expect(attachment.body).to include 'Fox'
    end

    it 'censors with rules globally (rather than the request)' do
      CensorRule.create!(
        text: 'dull', replacement: 'Horse',
        last_edit_editor: 'unknown', last_edit_comment: 'none'
      )
      subject
      expect(attachment.body).to_not include 'dull'
      expect(attachment.body).to include 'Horse'
    end
  end

  describe '#mask_later' do
    subject { foi_attachment.mask_later }

    let(:foi_attachment) { FactoryBot.create(:body_text) }

    it 'enqueues the job' do
      expect { subject }.
        to have_enqueued_job(FoiAttachmentMaskJob).with(foi_attachment)
    end
  end

  describe '#lock' do
    subject do
      foi_attachment.lock(editor: editor, reason: reason, extra: 'context')
    end

    let(:foi_attachment) { FactoryBot.create(:body_text, :unlocked) }

    let(:editor) { FactoryBot.create(:admin_user) }
    let(:reason) { 'Locking' }

    let(:info_request) { FactoryBot.create(:info_request) }

    before do
      allow(foi_attachment).to receive(:info_request).and_return(info_request)
    end

    it 'calls lock! with the given arguments' do
      expect(foi_attachment).to receive(:lock!).
        with(editor: editor, reason: reason, extra: 'context')
      subject
    end

    it 'expires the attachment' do
      expect(foi_attachment).to receive(:expire)
      subject
    end
  end

  describe '#lock!' do
    subject { foi_attachment.lock!(editor: editor, reason: reason) }

    let(:editor) { FactoryBot.create(:admin_user) }
    let(:reason) { 'Locking' }

    let(:info_request) { FactoryBot.create(:info_request) }

    before do
      allow(foi_attachment).to receive(:info_request).and_return(info_request)
    end

    def last_event
      foi_attachment.info_request.info_request_events.last
    end

    context 'when it is not locked' do
      let(:foi_attachment) { FactoryBot.create(:body_text, :unlocked) }

      it 'locks the attachment' do
        subject
        expect(foi_attachment.reload).to be_locked
      end

      it 'logs an event on the associated info_request' do
        expect { subject }.to change { last_event }
        expect(last_event.event_type).to eq('edit_attachment')
      end

      it { is_expected.to eq(true) }
    end

    context 'when it is already locked' do
      let(:foi_attachment) { FactoryBot.create(:body_text, :locked) }

      it 'remains locked' do
        subject
        expect(foi_attachment.reload).to be_locked
      end

      it 'does not log an event' do
        expect { subject }.not_to change { last_event }
      end

      it { is_expected.to eq(true) }
    end

    context 'when logging the event' do
      subject do
        foi_attachment.lock!(
          editor: editor,
          reason: reason,
          extra: 'context'
        )
      end

      let(:foi_attachment) { FactoryBot.create(:body_text, :unlocked) }

      it 'logs the required editor parameter' do
        subject
        expect(last_event.params[:editor]).to eq(editor)
      end

      it 'logs the required reason parameter' do
        subject
        expect(last_event.params[:reason]).to eq(reason)
      end

      it 'logs the optional additional parameters' do
        subject
        expect(last_event.params[:extra]).to eq('context')
      end
    end

    context 'when locking fails' do
      let(:foi_attachment) { FactoryBot.create(:body_text, :unlocked) }

      before do
        allow(foi_attachment).to receive(:update_and_log_event!).
          and_raise(ActiveRecord::RecordInvalid)
      end

      it 'raises an exception' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'does not lock the attachment' do
        expect do
          subject
        rescue ActiveRecord::RecordInvalid
          # expected
        end.not_to change { foi_attachment.reload.locked? }
      end

      it 'does not log an event' do
        expect do
          subject
        rescue ActiveRecord::RecordInvalid
          # expected
        end.not_to change { last_event }
      end
    end
  end

  describe '#unlock' do
    subject do
      foi_attachment.unlock(editor: editor, reason: reason, extra: 'context')
    end

    let(:foi_attachment) { FactoryBot.create(:body_text, :locked) }

    let(:editor) { FactoryBot.create(:admin_user) }
    let(:reason) { 'Unlocking' }

    let(:info_request) { FactoryBot.create(:info_request) }

    before do
      allow(foi_attachment).to receive(:info_request).and_return(info_request)
      # HACK: The FoiAttachment factory doesn't create the associations required
      # in order to access the mail object; it's incidental to this test so stub
      # it for now
      allow(foi_attachment).to receive(:mail_attributes).
        and_return(filename: 'original.txt')
    end

    it 'calls unlock! with the given arguments' do
      expect(foi_attachment).to receive(:unlock!).
        with(editor: editor, reason: reason, extra: 'context')
      subject
    end

    it 'expires the attachment' do
      expect(foi_attachment).to receive(:expire)
      subject
    end
  end

  describe '#unlock!' do
    subject { foi_attachment.unlock!(editor: editor, reason: reason) }

    let(:editor) { FactoryBot.create(:admin_user) }
    let(:reason) { 'Unlocking' }

    let(:info_request) { FactoryBot.create(:info_request) }

    before do
      allow(foi_attachment).to receive(:info_request).and_return(info_request)
      # HACK: The FoiAttachment factory doesn't create the associations required
      # in order to access the mail object; it's incidental to this test so stub
      # it for now
      allow(foi_attachment).to receive(:mail_attributes).
        and_return(filename: 'original.txt')
    end

    def last_event
      foi_attachment.info_request.info_request_events.last
    end

    context 'when it is locked' do
      let(:foi_attachment) { FactoryBot.create(:body_text, :locked) }

      it 'unlocks the attachment' do
        subject
        expect(foi_attachment.reload).to be_unlocked
      end

      it 'logs an event on the associated info_request' do
        expect { subject }.to change { last_event }
        expect(last_event.event_type).to eq('edit_attachment')
      end

      it { is_expected.to eq(true) }
    end

    context 'when it is already unlocked' do
      let(:foi_attachment) { FactoryBot.create(:body_text, :unlocked) }

      it 'remains unlocked' do
        subject
        expect(foi_attachment.reload).to be_unlocked
      end

      it 'does not log an event' do
        expect { subject }.not_to change { last_event }
      end

      it { is_expected.to eq(true) }
    end

    context 'when logging the event' do
      subject do
        foi_attachment.unlock!(
          editor: editor,
          reason: reason,
          extra: 'context'
        )
      end

      let(:foi_attachment) { FactoryBot.create(:body_text, :locked) }

      it 'logs the required editor parameter' do
        subject
        expect(last_event.params[:editor]).to eq(editor)
      end

      it 'logs the required reason parameter' do
        subject
        expect(last_event.params[:reason]).to eq(reason)
      end

      it 'logs the optional additional parameters' do
        subject
        expect(last_event.params[:extra]).to eq('context')
      end
    end

    context 'when unlocking fails' do
      let(:foi_attachment) { FactoryBot.create(:body_text, :locked) }

      before do
        allow(foi_attachment).to receive(:update_and_log_event!).
          and_raise(ActiveRecord::RecordInvalid)
      end

      it 'raises an exception' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'does not unlock the attachment' do
        expect do
          subject
        rescue ActiveRecord::RecordInvalid
          # expected
        end.not_to change { foi_attachment.reload.locked? }
      end

      it 'does not log an event' do
        expect do
          subject
        rescue ActiveRecord::RecordInvalid
          # expected
        end.not_to change { last_event }
      end
    end
  end

  describe '#unlocked?' do
    subject { foi_attachment.unlocked? }

    context 'when it is not locked' do
      let(:foi_attachment) { FactoryBot.build(:body_text, :unlocked) }
      it { is_expected.to eq(true) }
    end

    context 'when it is locked' do
      let(:foi_attachment) { FactoryBot.build(:body_text, :locked) }
      it { is_expected.to eq(false) }
    end
  end

  describe '#lockable?' do
    subject { foi_attachment.lockable? }

    context 'when it is unlocked' do
      let(:foi_attachment) { FactoryBot.build(:body_text, :unlocked) }
      it { is_expected.to eq(true) }
    end

    context 'when it is already locked' do
      let(:foi_attachment) { FactoryBot.build(:body_text, :locked) }
      it { is_expected.to eq(false) }
    end
  end

  describe '#unlockable?' do
    subject { foi_attachment.unlockable? }

    context 'when persisted' do
      let(:foi_attachment) { FactoryBot.build(:body_text) }
      it { is_expected.to eq(true) }
    end

    context 'when erased' do
      let(:foi_attachment) { FactoryBot.build(:body_text, :erased) }
      it { is_expected.to eq(false) }
    end
  end

  describe '#locking?' do
    let(:foi_attachment) { FactoryBot.create(:body_text, locked: false) }
    subject { foi_attachment.locking? }

    context 'when locked is unchanged' do
      it { is_expected.to eq false }
    end

    context 'when locked changed to true' do
      before { foi_attachment.locked = true }
      it { is_expected.to eq true }
    end

    context 'when locked changed to false' do
      before do
        foi_attachment.locked_will_change!
        foi_attachment.locked = false
      end

      it { is_expected.to eq false }
    end

    context 'when erased' do
      subject { foi_attachment.locking? }

      let(:foi_attachment) { FactoryBot.create(:body_text, :unlocked, :erased) }

      before { foi_attachment.locked = true }

      it { is_expected.to eq false }
    end
  end

  describe '#unlocking?' do
    let(:foi_attachment) { FactoryBot.create(:body_text, locked: true) }
    subject { foi_attachment.unlocking? }

    context 'when locked is unchanged' do
      it { is_expected.to eq false }
    end

    context 'when locked changed to true' do
      before { foi_attachment.locked = false }
      it { is_expected.to eq true }
    end

    context 'when locked changed to false' do
      before do
        foi_attachment.locked_will_change!
        foi_attachment.locked = true
      end

      it { is_expected.to eq false }
    end

    context 'when erased' do
      subject { foi_attachment.unlocking? }

      let(:foi_attachment) { FactoryBot.create(:body_text, :locked, :erased) }

      before { foi_attachment.locked = false }

      it { is_expected.to eq false }
    end
  end

  describe '#replacing?' do
    let(:foi_attachment) { FactoryBot.create(:body_text) }
    subject { foi_attachment.replacing? }

    context 'when unlocking' do
      before do
        allow(foi_attachment).to receive(:unlocking?).and_return(true)
        foi_attachment.replacement_file = StringIO.new('foo')
        foi_attachment.replacement_body = 'foo'
      end

      it { is_expected.to eq false }
    end

    context 'when file has changed' do
      before { foi_attachment.replacement_file = StringIO.new('foo') }
      it { is_expected.to eq true }
    end

    context 'when body has changed' do
      before { foi_attachment.replacement_body = 'foo' }
      it { is_expected.to eq true }
    end

    context 'when erased' do
      subject { foi_attachment.replacing? }

      let(:foi_attachment) { FactoryBot.create(:body_text, :erased) }

      before do
        allow(foi_attachment).to receive(:replacement_file_changed?).
          and_return(false)
        allow(foi_attachment).to receive(:replacement_body_changed?).
          and_return(true)
      end

      it { is_expected.to eq false }
    end
  end

  describe '#replaced?' do
    let(:foi_attachment) { FactoryBot.create(:body_text) }
    subject { foi_attachment.replaced? }

    context 'when replaced_at is set' do
      before { foi_attachment.replaced_at = Time.now }
      it { is_expected.to eq true }
    end

    context 'when replaced_at is unset' do
      before { foi_attachment.replaced_at = nil }
      it { is_expected.to eq false }
    end

    context 'when erased' do
      subject { foi_attachment.replaced? }

      let(:foi_attachment) do
        # Create first with replaced_reason, then set erased_at
        attachment = FactoryBot.create(:body_text,
                                       replaced_at: Time.zone.now,
                                       replaced_reason: 'Test reason')
        attachment.update_column(:erased_at, Time.zone.now)
        attachment
      end

      it { is_expected.to eq false }
    end
  end

  describe '#replacing_or_replaced?' do
    let(:foi_attachment) { FactoryBot.create(:body_text) }
    subject { foi_attachment.replacing_or_replaced? }

    context 'when replacing' do
      before { allow(foi_attachment).to receive(:replacing?).and_return(true) }
      it { is_expected.to eq true }
    end

    context 'when replaced' do
      before { allow(foi_attachment).to receive(:replaced?).and_return(true) }
      it { is_expected.to eq true }
    end

    context 'when neither replacing or replaced' do
      before do
        allow(foi_attachment).to receive(:replacing?).and_return(false)
        allow(foi_attachment).to receive(:replaced?).and_return(false)
      end

      it { is_expected.to eq false }
    end

    context 'when erased' do
      subject { foi_attachment.replacing_or_replaced? }

      let(:foi_attachment) { FactoryBot.create(:body_text, :erased) }

      before do
        allow(foi_attachment).to receive(:replacing?).and_return(true)
        allow(foi_attachment).to receive(:replaced?).and_return(true)
      end

      it { is_expected.to eq false }
    end
  end

  describe '#raw_email_erased?' do
    let(:foi_attachment) { FactoryBot.build(:body_text) }

    it 'delegates to info_request' do
      expect(foi_attachment.incoming_message).to receive(:raw_email_erased?)
      foi_attachment.raw_email_erased?
    end
  end

  describe '#erased?' do
    subject { foi_attachment.erased? }

    context 'when erased_at is nil' do
      let(:foi_attachment) { FactoryBot.build(:body_text) }
      it { is_expected.to be false }
    end

    context 'when erased_at is present' do
      let(:foi_attachment) { FactoryBot.build(:body_text, :erased) }
      it { is_expected.to be true }
    end

    context 'when erased_at is nil but raw email has been erased' do
      let(:foi_attachment) { FactoryBot.build(:body_text) }

      before do
        allow(foi_attachment).to receive(:raw_email_erased?).and_return(true)
      end

      it { is_expected.to be true }
    end
  end

  describe '#erase' do
    subject { foi_attachment.erase(editor: editor, reason: reason) }

    let(:info_request) { FactoryBot.create(:info_request_with_incoming) }
    let(:incoming_message) { info_request.incoming_messages.first }

    let(:foi_attachment) do
      FactoryBot.create(
        :body_text,
        filename: 'bob.txt',
        incoming_message: incoming_message
      )
    end

    let(:editor) { FactoryBot.create(:admin_user) }
    let(:reason) { 'Removing PII' }

    it 'purges later' do
      expect { subject }.to have_enqueued_job(ActiveStorage::PurgeJob)
    end

    it 'removes filename' do
      expect { subject }.to change(foi_attachment, :filename).
        from('bob.txt').to('attachment.txt')
    end

    it 'purges the attached file' do
      subject
      expect(foi_attachment.reload.file).not_to be_attached
    end

    it 'touches erased_at' do
      expect { subject }.to change(foi_attachment, :erased_at).from(nil)
      expect(foi_attachment.erased_at).to be_a(Time)
    end

    def last_event
      info_request.info_request_events.last
    end

    it 'logs an event on the associated info_request' do
      expect { subject }.to change { last_event }
      expect(last_event.event_type).to eq('erase_attachment')
    end

    it 'expires the associated info_request' do
      expect(foi_attachment.info_request).to receive(:expire)
      subject
    end

    it { is_expected.to eq(true) }

    context 'when already erased' do
      before { allow(foi_attachment).to receive(:erased?).and_return(true) }

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::AlreadyErasedError)
      end
    end

    context 'when an event cannot be logged' do
      before do
        expect(foi_attachment).to receive(:log_event).and_return(false)
      end

      it 'does not erase the file' do
        subject
        perform_enqueued_jobs
        expect(foi_attachment.reload).not_to be_erased
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
        expect(foi_attachment.reload).not_to be_erased
      end

      it { is_expected.to eq(false) }
    end

    context 'when the record cannot be touched' do
      before do
        expect(foi_attachment).
          to receive(:touch).and_raise(ActiveRecord::ActiveRecordError)
      end

      it 'does not erase the file' do
        subject
        expect(foi_attachment.reload).not_to be_erased
      end

      it { is_expected.to eq(false) }
    end

    context 'when the info request cannot be expired' do
      before do
        expect(foi_attachment).to receive(:expire).and_raise(StandardError)
      end

      it 'does not erase the file' do
        subject
        expect(foi_attachment.reload).not_to be_erased
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#replacement_body' do
    let(:foi_attachment) { FactoryBot.create(:body_text) }

    before do
      allow(foi_attachment).to receive(:body).and_return('hello'.b)
    end

    context 'when set' do
      it 'returns the set value' do
        foi_attachment.replacement_body = 'goodbye'
        expect(foi_attachment.replacement_body).to eq('goodbye')
      end
    end

    context 'when unset' do
      it 'returns the original body' do
        expect(foi_attachment.replacement_body).to eq('hello')
      end

      it 'returns a UTF-8 string of the original body' do
        expect(foi_attachment.replacement_body.is_utf8?).to eq(true)
      end
    end
  end

  describe '#replacement_body=' do
    let(:foi_attachment) { FactoryBot.create(:body_text) }
    let(:original_body) { "Original content\n" }
    let(:identical_body_windows) { "Original content\r\n" }
    let(:different_body) { "Different content" }

    before do
      allow(foi_attachment).to receive(:body).and_return(original_body)
    end

    it 'does not set the replacement body if content is the same (normalizing line endings)' do
      foi_attachment.replacement_body = identical_body_windows
      expect(foi_attachment.replacement_body).to eq original_body
    end

    it 'sets the replacement body if content is different' do
      foi_attachment.replacement_body = different_body
      expect(foi_attachment.replacement_body).to eq different_body
    end
  end

  describe '#handle_locked' do
    let(:foi_attachment) { FactoryBot.create(:body_text) }
    let(:original_body) { 'The original body content' }

    before do
      allow(foi_attachment).to receive(:mail_attributes).
        and_return(body: original_body)

      allow(foi_attachment).to receive(:incoming_message).
        and_return(double(raw_email_erased?: false))
    end

    context 'when locking an unmasked attachment' do
      let(:foi_attachment) { FactoryBot.create(:body_text, :unmasked) }

      it 'masks the attachment' do
        expect(foi_attachment).to receive(:mask_later)
        foi_attachment.update(locked: true)
      end
    end

    context 'when locking attachment with redacted filename' do
      let(:info_request) { FactoryBot.create(:info_request, :with_incoming) }
      let(:foi_attachment) { info_request.foi_attachments.first }

      before do
        FactoryBot.create(
          :censor_rule,
          info_request: info_request,
          text: foi_attachment.filename,
          replacement: 'redacted.txt'
        )
      end

      it 'retains redacted filename' do
        expect { foi_attachment.update(locked: true) }.
          to_not change(foi_attachment, :display_filename).from('redacted.txt')
      end
    end

    context 'when locking an masked attachment' do
      let(:foi_attachment) { FactoryBot.create(:body_text, masked_at: 1.day.ago) }

      it 'does not mask the attachment' do
        expect(foi_attachment).to_not receive(:mask_later)
        foi_attachment.update(locked: true)
      end
    end

    context 'when unlocking an attachment' do
      let(:foi_attachment) { FactoryBot.create(:body_text, :locked) }
      let(:new_body) { "This is a new body" }

      it 'masks the attachment even if already masked' do
        expect(foi_attachment.masked_at).to_not be_nil
        expect(foi_attachment).to receive(:mask_later)
        foi_attachment.update(locked: false)
      end

      it 'does not process replacements when unlocking' do
        foi_attachment.replacement_body = new_body
        expect(foi_attachment.file_blob).not_to receive(:upload)
        foi_attachment.update(locked: false)
      end
    end

    context 'when unlocking a replaced attachment' do
      let(:foi_attachment) do
        FactoryBot.create(:body_text, :replaced, replacement_body: 'New body')
      end

      it 'resets body to original content' do
        # ensure FoiAttachmentMaskJob isn't run when calling #body - it'll break
        # due to there being no associated incoming_message/info_request
        allow(foi_attachment).to receive(:masked?).and_return(true)

        expect { foi_attachment.update(locked: false) }.
          to change(foi_attachment, :body).
          from('New body').to(original_body)
      end

      it 'resets replaced_at' do
        expect { foi_attachment.update(locked: false) }.
          to change(foi_attachment, :replaced_at).
          to(nil)
      end

      it 'resets replaced_reason' do
        expect { foi_attachment.update(locked: false) }.
          to change(foi_attachment, :replaced_reason).
          to(nil)
      end
    end
  end

  describe '#handle_replacements' do
    let(:foi_attachment) { FactoryBot.create(:body_text) }

    before { foi_attachment.replaced_reason = 'GDPR case' }

    context 'with replacement file' do
      let(:replacement) { fixture_file_upload('interesting.csv', 'text/csv') }

      it 'locks the attachment' do
        foi_attachment.replacement_file = replacement
        foi_attachment.save
        expect(foi_attachment.locked?).to be true
      end

      it 'uploads the replacement file to active storage' do
        expect(foi_attachment.file).to receive(:attach).with(
          io: replacement,
          filename: 'interesting.csv.txt',
          content_type: 'text/plain'
        )
        foi_attachment.replacement_file = replacement
        foi_attachment.save
      end
    end

    context 'with replacement body' do
      let(:new_body) { "This is the new body content" }

      before do
        allow(foi_attachment).to receive(:mail_attributes).
          and_return(body: 'The original body content', filename: 'foo')
      end

      it 'locks the attachment' do
        foi_attachment.replacement_body = new_body
        foi_attachment.save
        expect(foi_attachment.locked?).to be true
      end

      it 'uploads the replacement body to active storage' do
        expect(foi_attachment.file_blob).to receive(:upload) do |io, options|
          expect(io.read).to eq(new_body)
          expect(options).to eq(identify: false)
        end
        expect(foi_attachment.file_blob).to receive(:save)
        foi_attachment.replacement_body = new_body
        foi_attachment.save
      end
    end

    context 'filename selection' do
      let(:new_body) { 'Replacement content' }

      before do
        foi_attachment.filename = 'current.txt'
        allow(foi_attachment).to receive(:mail_attributes).
          and_return(body: 'Original', filename: 'attachment.txt')
      end

      context 'when replaced_filename is provided' do
        it 'uses the replaced_filename' do
          foi_attachment.replaced_filename = 'custom.txt'
          foi_attachment.replacement_body = new_body
          foi_attachment.save
          expect(foi_attachment.filename).to eq('custom.txt')
        end
      end

      context 'when replaced_filename is blank and replacement_file is present' do
        let(:replacement) do
          fixture_file_upload('interesting.csv', 'text/csv')
        end

        it 'uses the replacement file original_filename' do
          foi_attachment.replaced_filename = ''
          foi_attachment.replacement_file = replacement
          foi_attachment.save
          # FIXME: Ideally this would eq('interesting.csv')
          # See https://github.com/mysociety/alaveteli/issues/9016
          expect(foi_attachment.filename).to eq('interesting.csv.txt')
        end
      end

      context 'when replaced_filename and replacement_file are blank' do
        it 'uses the current filename' do
          foi_attachment.replaced_filename = ''
          foi_attachment.replacement_body = new_body
          foi_attachment.save
          expect(foi_attachment.filename).to eq('current.txt')
        end
      end

      context 'when all other options are blank' do
        it 'falls back to mail_attributes filename' do
          foi_attachment.filename = nil
          foi_attachment.replaced_filename = ''
          foi_attachment.replacement_body = new_body
          foi_attachment.save
          expect(foi_attachment.filename).to eq('attachment.txt')
        end
      end
    end
  end

  describe '#storage_key' do
    let(:foi_attachment) { FactoryBot.create(:foi_attachment) }

    context 'when file is attached' do
      it 'returns the blob key' do
        expect(foi_attachment.file).to be_attached
        storage_key = foi_attachment.storage_key
        expect(storage_key).to eq(foi_attachment.file.blob.key)
      end
    end

    context 'when file is not attached' do
      before do
        allow(foi_attachment).to receive(:file).
          and_return(double(attached?: false))
      end

      it 'returns nil' do
        expect(foi_attachment.storage_key).to be_nil
      end
    end
  end
end
