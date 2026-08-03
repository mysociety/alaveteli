require 'spec_helper'

RSpec.describe FoiAttachment::MaskJob, type: :job do
  let(:info_request) { FactoryBot.create(:info_request_with_html_attachment) }
  let(:incoming_message) { info_request.incoming_messages.first }
  let(:attachment) { incoming_message.foi_attachments.last }

  def perform
    described_class.new.perform(attachment)
  end

  before { rebuild_raw_emails(info_request) }

  describe 'uniqueness' do
    let(:attachment_1) { incoming_message.foi_attachments.first }
    let(:attachment_2) { incoming_message.foi_attachments.last }

    before { described_class.unlock! }
    after { described_class.unlock! }

    it 'does not enqueue duplicate jobs for the same attachment' do
      expect {
        described_class.perform_later(attachment_1)
        described_class.perform_later(attachment_1)
      }.to have_enqueued_job(described_class).exactly(:once)
    end

    it 'enqueues jobs for sibling attachments of the same message' do
      expect {
        described_class.perform_later(attachment_1)
        described_class.perform_later(attachment_2)
      }.to have_enqueued_job(described_class).twice
    end
  end

  context 'when masking times out' do
    before do
      allow(attachment).to receive(:apply_masks).and_raise(Regexp::TimeoutError)
      allow_any_instance_of(described_class).
        to receive(:send_exception_notifications?).and_return(true)
      allow(ExceptionNotifier).to receive(:notify_exception)
    end

    it 'records the failure without raising' do
      expect { perform }.to_not raise_error
      expect(attachment.masking_failed_at).to be_present
    end

    it 'notifies once on the first failure' do
      expect(ExceptionNotifier).to receive(:notify_exception).once
      perform
    end

    it 'does not notify when the attachment already failed' do
      attachment.update_column(:masking_failed_at, Time.zone.now)
      expect(ExceptionNotifier).to_not receive(:notify_exception)
      perform
    end
  end

  context 'after rescuing from FoiAttachment::MissingError' do
    before do
      # first call to #unmasked_body should raise MissingError exception
      # subsequent calls should call the original method.
      @raised = false
      allow(attachment).to receive(:unmasked_body).
        and_wrap_original do |original_method, *args, &block|
          unless @raised
            @raised = true
            raise FoiAttachment::MissingError
          end
          original_method.call(*args, &block)
        end
    end

    it 'parses raw email again' do
      expect(incoming_message).to receive(:parse_raw_email!)
      perform
    end

    it 'masks the body' do
      CensorRule.create!(
        text: 'dull', replacement: 'Orange',
        last_edit_editor: 'unknown', last_edit_comment: 'none'
      )
      perform
      expect(attachment.body).to include 'Orange'
    end

    it 'rebuilds the attachment and masks if the hexdigest does not match' do
      CensorRule.create!(
        text: 'dull', replacement: 'Banana',
        last_edit_editor: 'unknown', last_edit_comment: 'none'
      )

      attachment.update(hexdigest: '123')
      perform

      new_attachment = IncomingMessage.
        get_attachment_by_url_part_number_and_filename!(
          incoming_message.get_attachments_for_display,
          attachment.url_part_number,
          attachment.display_filename
        )
      expect(new_attachment.unmasked_body).to include 'dull'
      expect(new_attachment.body).to include 'Banana'
    end
  end
end
