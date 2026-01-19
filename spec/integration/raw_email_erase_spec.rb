require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe 'Erasing raw emails' do
  include ActiveJob::TestHelper

  let!(:admin) { FactoryBot.create(:admin_user) }
  let(:request) { FactoryBot.create(:info_request) }

  let(:mail) do
    Mail.new do |m|
      m.to = request.incoming_email
      m.attachments['attachment.txt'] = 'This is main body part'
      m.attachments['document.txt'] = 'This is a text document attachment'
    end
  end

  let(:incoming_message) do
    request.receive(mail, mail.to_s)
    request.incoming_messages.last
  end

  let(:raw_email) { incoming_message.raw_email }
  let(:attachment) { incoming_message.foi_attachments.last }

  before do
    incoming_message.parse_raw_email!
  end

  def jobs
    ActiveJob::Base.queue_adapter.enqueued_jobs.map { _1['job_class'] }
  end

  describe 'unmasked attachment after raw email erasure' do
    it 'cannot be masked when censor rule triggers re-masking' do
      # Attachment isn't masked until viewed
      expect(attachment.locked).to eq(false)
      expect(attachment.masked?).to eq(false)

      # User views the attachment on public frontend
      FoiAttachmentMaskJob.perform_later(attachment)
      perform_enqueued_jobs
      attachment.reload
      expect(attachment.locked).to eq(false)
      expect(attachment.masked?).to eq(true)

      # Admin creates a censor rule which triggers cache expiry
      rule = FactoryBot.create(
        :info_request_censor_rule,
        info_request: request,
        text: 'PII',
        replacement: '[REDACTED]'
      )
      perform_enqueued_jobs do
        rule.expire_requests
      end
      attachment.reload
      expect(attachment.locked).to eq(false)
      expect(attachment.masked?).to eq(false)

      expect(jobs).to be_empty

      # Before the attachment is viewed again an admin erases the raw email
      result = raw_email.erase(
        editor: admin,
        reason: 'Contains PII'
      )
      expect(result).to eq(true)

      raw_email.reload
      expect(raw_email.erased?).to eq(true)

      # We attempt to ensure attachments are masked before the raw email is
      # erased but there can be a race condition error in Sidekiq if
      # FoiAttachmentMaskJob runs after RawEmail#erased_at is set
      expect { perform_enqueued_jobs }.to raise_error(IncomingMessage::RawEmailErasedError)
      expect(jobs).to_not be_empty

      # Twice for both attachments
      expect { perform_enqueued_jobs }.to raise_error(IncomingMessage::RawEmailErasedError)
      expect(jobs).to_not be_empty

      # Sidekiq will continue to perform jobs until the queue is empty
      perform_enqueued_jobs
      expect(jobs).to be_empty

      # Attachment remains unmasked - this is the problematic state
      attachment.reload
      expect(attachment.locked).to eq(true)
      expect(attachment.masked?).to eq(false)

      visit get_attachment_url(
        request.url_title,
        incoming_message_id: attachment.incoming_message_id,
        part: attachment.url_part_number,
        file_name: attachment.display_filename
      )
      expect(page).to have_http_status(:ok)

      # PROBLEM: Attempting to view the attachment triggers masking
      expect(page).not_to have_content('Attachment processing')
    end
  end
end
