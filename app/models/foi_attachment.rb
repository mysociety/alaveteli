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

# models/foi_attachment.rb:
# An attachment to an email (IncomingMessage)
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/
# This is the type which is used to send data about attachments to the view

require 'digest'

class FoiAttachment < ApplicationRecord
  include Rails.application.routes.url_helpers
  include LinkToHelper

  include MessageProminence

  include Eventable
  include Lockable
  include Maskable
  include Replaceable

  MissingAttachment = Class.new(StandardError)
  AlreadyErasedError = Class.new(StandardError)

  belongs_to :incoming_message, inverse_of: :foi_attachments, optional: true
  has_one :raw_email, through: :incoming_message, source: :raw_email
  has_one :info_request, through: :incoming_message, source: :info_request
  has_one :user, through: :info_request

  has_one_attached :file, service: :attachments

  validates_presence_of :content_type
  validates_presence_of :filename
  validates_presence_of :display_size

  before_validation :ensure_filename!, only: [:filename]
  before_destroy :delete_cached_file!

  scope :binary, -> { where.not(content_type: AlaveteliTextMasker::TextMask) }
  scope :erased, -> { where.not(erased_at: nil) }

  delegate :expire, to: :info_request
  delegate :raw_email_erased?, to: :incoming_message
  delegate :metadata, to: :file_blob, allow_nil: true

  admin_columns exclude: %i[url_part_number within_rfc822_subject hexdigest],
                include: %i[redacted_filename display_filename metadata]

  BODY_MAX_TRIES = 3
  BODY_MAX_DELAY = 5

  # rubocop:disable Layout/LineLength
  CONTENT_TYPE_NAMES = {
    # Plain Text
    "text/plain" => 'Text file',
    'application/rtf' => 'RTF file',

    # Binary Documents
    'application/pdf' => 'PDF file',

    # Images
    'image/tiff' => 'TIFF image',

    # Word Processing
    'application/vnd.ms-word' => 'Word document',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'Word document',

    # Presentation
    'application/vnd.ms-powerpoint' => 'PowerPoint presentation',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation' => 'PowerPoint presentation',

    # Spreadsheet
    'application/vnd.ms-excel' => 'Excel spreadsheet',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'Excel spreadsheet'
  }.freeze
  # rubocop:enable Layout/LineLength

  def delete_cached_file!
    @cached_body = nil
    file.purge_later if file.attached?
  end

  def body=(d)
    self.hexdigest ||= Digest::MD5.hexdigest(d)

    ensure_filename!
    if file.attached?
      file_blob.upload(StringIO.new(d.to_s), identify: false)
      file_blob.save

    else
      file.attach(
        io: StringIO.new(d.to_s),
        filename: filename,
        content_type: content_type
      )
    end

    @cached_body = d.force_encoding("ASCII-8BIT")
    update_display_size!
  end

  def retained!
    return true if retained?

    raise MissingAttachment, "attachment has been erased (ID=#{id})"
  end

  def body
    return @cached_body if @cached_body
    return unless retained!

    begin
      return file.download if locked? || masked?
    rescue ActiveStorage::FileNotFoundError => ex
      # file isn't in storage and has gone missing, rescue to allow the masking
      # job to run and rebuild the stored file or even the whole attachment.
      raise ex if locked? || erased?
    end

    if persisted?
      FoiAttachmentMaskJob.unlock!(self)
      FoiAttachmentMaskJob.perform_now(self)
      return body unless destroyed?
    end

    load_attachment_from_incoming_message!.body if destroyed?
  end

  # body as UTF-8 text, with scrubbing of invalid chars if needed
  def body_as_text
    convert_string_to_utf8(body, 'UTF-8') if retained!
  end

  # for text types, the scrubbed UTF-8 text. For all other types, the
  # raw binary
  def default_body
    text_type? ? body_as_text.string : body if retained!
  end

  # return the body as it is in the raw email, unmasked without censor rules
  # applied
  def unmasked_body
    mail_attributes[:body] if retained!
  end

  def main_body_part?
    self == incoming_message.get_main_body_text_part
  end

  # Returns HTML, of extra comment to put by attachment
  def extra_note
    return unless content_type == 'message/delivery-status'

    dsn = DeliveryStatusNotification.new(body)
    return unless dsn.status && dsn.message

    "DSN: #{dsn.status} #{dsn.message}"
  end

  # Called by controller so old filenames still work
  def old_display_filename
    filename = self.filename

    # Convert weird spaces (e.g. \n) to normal ones
    filename = filename.gsub(/\s/, " ")
    # Remove slashes, they mess with URLs
    filename.gsub(/\//, "-")
  end

  def redacted_filename
    return replaced_filename if replaced_filename.present?
    return filename unless info_request
    return filename if locked? && !locking?

    info_request.apply_censor_rules_to_text(filename)
  end

  # TODO: changing this will break existing URLs, so have a care - maybe
  # make another old_display_filename see above
  def display_filename
    # Sometimes filenames have e.g. %20 in - no point butchering that
    # (without unescaping it, this would remove the % and leave 20s in there)
    filename = CGI.unescape(redacted_filename)
    # Remove weird spaces
    filename = filename.gsub(/\s+/, " ")
    # Remove non-alphabetic characters
    filename = filename.gsub(/[^A-Za-z0-9.]/, " ")
    # Remove spaces near dots
    filename = filename.gsub(/\s*\.\s*/, ".")
    # Compress adjacent spaces down to a single one
    filename = filename.gsub(/\s+/, " ")
    # Strip leading/trailing whitespace
    filename.strip
  end

  def ensure_filename!
    if filename.blank?
      calc_ext = AlaveteliFileTypes.mimetype_to_extension(content_type)
      calc_ext = "bin" unless calc_ext
      if !within_rfc822_subject.nil?
        computed = within_rfc822_subject + "." + calc_ext
      else
        computed = "attachment." + calc_ext
      end
      self.filename = computed
    end
  end

  def filename=(filename)
    filename.try(:delete!, "\0")
    calc_ext = AlaveteliFileTypes.mimetype_to_extension(content_type)
    # Put right extension on if missing
    if !filename.nil? && !filename.match(/\.#{calc_ext}$/) && calc_ext
      computed = filename + "." + calc_ext
    else
      computed = filename
    end
    write_attribute('filename', computed)
  end

  # Size to show next to the download link for the attachment
  def update_display_size!
    s = body.size

    if s > 1024 * 1024
      self.display_size = format("%.1f", s.to_f / 1024 / 1024) + 'M'
    else
      self.display_size = (s / 1024).to_s + 'K'
    end
  end

  # Whether this type has a "View as HTML"
  def has_body_as_html?
    return false unless retained?

    AttachmentToHTML.extractable?(self)
  end

  # Name of type of attachment type - only valid for things that
  # has_body_as_html?
  def name_of_content_type
    CONTENT_TYPE_NAMES[content_type]
  end

  # For "View as HTML" of attachment
  def body_as_html(**kwargs)
    AttachmentToHTML.to_html(self, **kwargs) if retained!
  end

  def cached_urls
    [
      request_path(info_request)
    ]
  end

  def load_attachment_from_incoming_message
    IncomingMessage.get_attachment_by_url_part_number_and_filename!(
      incoming_message.get_attachments_for_display,
      url_part_number,
      display_filename
    )
  end

  def erased?
    erased_at.present?
  end

  def retained?
    !erased? && !raw_email_erased?
  end

  def erase(editor:, reason:)
    raise AlreadyErasedError unless retained?

    transaction do |t|
      t.after_rollback { return false }

      raise ActiveRecord::Rollback unless
        log_event(
          'erase_attachment',
          editor: editor,
          reason: reason,
          attachment: self,
          storage_key: storage_key
        )

      self.filename = nil
      ensure_filename!

      delete_cached_file!
      touch(:erased_at)

      expire

      true
    end
  end

  def storage_key
    file.blob.key if file&.attached?
  end

  private

  def mail_attributes
    MailHandler.attachment_attributes_for_hexdigest(
      raw_email.mail,
      hexdigest: hexdigest
    )

  rescue MailHandler::MismatchedAttachmentHexdigest
    begin
      attributes = MailHandler.attempt_to_find_original_attachment_attributes(
        raw_email.mail,
        body: file.download
      ) if file.attached?

    rescue ActiveStorage::FileNotFoundError
      raise MissingAttachment, "attachment missing from storage (ID=#{id})"
    end

    unless attributes
      raise MissingAttachment, "attachment missing in raw email (ID=#{id})"
    end

    update(hexdigest: attributes[:hexdigest])
    attributes
  end

  def load_attachment_from_incoming_message!
    attachment = load_attachment_from_incoming_message
    return attachment if attachment

    raise MissingAttachment, "attachment couldn't be reloaded using " \
      "url_part_number and display_filename attributes"
  end

  def text_type?
    AlaveteliTextMasker::TextMask.include?(content_type)
  end
end
