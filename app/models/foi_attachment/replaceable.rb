# Handles the replacement of FoiAttachment files.
module FoiAttachment::Replaceable
  extend ActiveSupport::Concern

  included do
    attribute :replacement_file
    attribute :replacement_body, :string
    attribute :replaced_filename, :string

    validates :replaced_filename, absence: true, unless: :replacing_or_replaced?
    validates :replaced_reason, absence: true, unless: :replacing_or_replaced?
    validates :replaced_reason, presence: true, if: :replacing_or_replaced?

    before_save :handle_replacements
  end

  def replacing?
    !erased? && !unlocking? &&
      (replacement_file_changed? || replacement_body_changed?)
  end

  def replaced?
    !erased? && replaced_at.present?
  end

  def replacing_or_replaced?
    !erased? && (replacing? || replaced?)
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

  def handle_replacements
    if replacing? || (replaced? && replaced_filename_changed?)
      self.filename = replaced_filename.presence ||
                      replacement_file&.original_filename ||
                      filename ||
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
