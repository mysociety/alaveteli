# == Schema Information
# Schema version: 20250408105243
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

  MissingAttachment = Class.new(StandardError)

  attribute :replacement_file
  attribute :replacement_body, :string
  attribute :replaced_filename, :string

  belongs_to :incoming_message, inverse_of: :foi_attachments, optional: true
  has_one :info_request, through: :incoming_message, source: :info_request
  has_one :raw_email, through: :incoming_message, source: :raw_email

  has_one_attached :file, service: :attachments

  validates_presence_of :content_type
  validates_presence_of :filename
  validates_presence_of :display_size
  validates :replaced_filename, absence: true, unless: :replacing_or_replaced?
  validates :replaced_reason, absence: true, unless: :replacing_or_replaced?
  validates :replaced_reason, presence: true, if: :replacing_or_replaced?

  before_validation :ensure_filename!, only: [:filename]
  before_save :handle_locked
  before_save :handle_replacements
  before_destroy :delete_cached_file!

  scope :binary, -> { where.not(content_type: AlaveteliTextMasker::TextMask) }
  scope :locked, -> { where(locked: true) }
  scope :unlocked, -> { where(locked: false) }

  delegate :expire, :log_event, to: :info_request
  delegate :metadata, to: :file_blob, allow_nil: true

  admin_columns exclude: %i[url_part_number within_rfc822_subject hexdigest],
                include: %i[metadata]

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
    file.purge if file.attached?
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

  def body
    return @cached_body if @cached_body

    begin
      return file.download if locked? || masked?
    rescue ActiveStorage::FileNotFoundError => ex
      # file isn't in storage and has gone missing, rescue to allow the masking
      # job to run and rebuild the stored file or even the whole attachment.
      raise ex if locked?
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
    convert_string_to_utf8(body, 'UTF-8')
  end

  # for text types, the scrubbed UTF-8 text. For all other types, the
  # raw binary
  def default_body
    text_type? ? body_as_text.string : body
  end

  # return the body as it is in the raw email, unmasked without censor rules
  # applied
  def unmasked_body
    mail_attributes[:body]
  end

  def masked?
    file.attached? && masked_at.present? && masked_at < Time.zone.now
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

  # TODO: changing this will break existing URLs, so have a care - maybe
  # make another old_display_filename see above
  def display_filename
    filename = self.filename
    unless locked? || incoming_message.nil?
      filename = info_request.apply_censor_rules_to_text(filename)
    end
    # Sometimes filenames have e.g. %20 in - no point butchering that
    # (without unescaping it, this would remove the % and leave 20s in there)
    filename = CGI.unescape(filename)

    # Remove weird spaces
    filename = filename.gsub(/\s+/, " ")
    # Remove non-alphabetic characters
    filename = filename.gsub(/[^A-Za-z0-9.]/, " ")
    # Remove spaces near dots
    filename = filename.gsub(/\s*\.\s*/, ".")
    # Compress adjacent spaces down to a single one
    filename = filename.gsub(/\s+/, " ")
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
    AttachmentToHTML.extractable?(self)
  end

  # Name of type of attachment type - only valid for things that
  # has_body_as_html?
  def name_of_content_type
    CONTENT_TYPE_NAMES[content_type]
  end

  # For "View as HTML" of attachment
  def body_as_html(dir, opts = {})
    attachment_url = opts.fetch(:attachment_url, nil)
    to_html_opts = opts.merge(tmpdir: dir, attachment_url: attachment_url)
    AttachmentToHTML.to_html(self, to_html_opts)
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

  def update_and_log_event(event: {}, **params)
    return false unless update(params)

    replaced = locked? && (
               replacement_body_previously_changed? ||
               replacement_file_previously_changed?)

    log_event(
      'edit_attachment',
      event.merge(
        attachment_id: id,
        old_locked: locked_previously_was,
        locked: locked,
        replaced: replaced,
        replaced_at: replaced ? replaced_at : nil,
        replaced_filename: replaced ? filename : nil,
        replaced_reason: replaced ? replaced_reason : nil,
        old_prominence: prominence_previously_was,
        prominence: prominence,
        old_prominence_reason: prominence_reason_previously_was,
        prominence_reason: prominence_reason
      )
    )
  end

  def locking?
    locked? && locked_changed?
  end

  def unlocking?
    !locked? && locked_changed?
  end

  def replacing?
    !unlocking? && (replacement_file_changed? || replacement_body_changed?)
  end

  def replaced?
    replaced_at.present?
  end

  def replacing_or_replaced?
    replacing? || replaced?
  end

  def replaced_filename
    return filename if replaced? && !replaced_filename_changed?

    super
  end

  def replacement_body
    super || normalize_string_to_utf8(body)
  end

  def replacement_body=(new_replacement_body)
    super unless normalize_line_endings(new_replacement_body) ==
                 normalize_line_endings(body)
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

  def handle_locked
    if unlocking? && replaced?
      file_blob.upload(StringIO.new(unmasked_body), identify: false)
      file_blob.save

      self.replaced_at = nil
      self.replaced_reason = nil
    end

    if unlocking?
      self.masked_at = nil
      self.filename = mail_attributes[:filename]
      ensure_filename!
    end

    if locking? || unlocking?
      FoiAttachmentMaskJob.perform_later(self) unless masked_at
    end

    true
  end

  def handle_replacements
    if replacing? || (replaced? && replaced_filename_changed?)
      self.filename = replaced_filename.presence ||
                      replacement_file&.original_filename ||
                      mail_attributes[:filename]
      ensure_filename!
    end

    if replacing?
      self.replaced_at = Time.zone.now
      self.masked_at = Time.zone.now
      self.locked = true

      if replacement_file_changed?
        file.attach(
          io: replacement_file,
          filename: filename,
          content_type: content_type
        )
      elsif replacement_body_changed?
        file_blob.upload(StringIO.new(replacement_body), identify: false)
        file_blob.save
      end
    end

    true
  end
end
