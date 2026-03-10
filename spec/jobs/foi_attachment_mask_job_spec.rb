require 'spec_helper'

RSpec.describe FoiAttachmentMaskJob, type: :job do
  let(:info_request) { FactoryBot.create(:info_request_with_html_attachment) }
  let(:incoming_message) { info_request.incoming_messages.first }
  let(:attachment) { incoming_message.foi_attachments.last }

  def perform
    described_class.new.perform(attachment)
  end

  before { rebuild_raw_emails(info_request) }

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
