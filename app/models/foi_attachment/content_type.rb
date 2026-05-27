# Deal with the content type of attachments
module FoiAttachment::ContentType
  extend ActiveSupport::Concern

  # rubocop:disable Layout/LineLength
  CONTENT_TYPE_NAMES = {
    # Plain Text
    "text/plain" => _('Text file'),
    'application/rtf' => _('RTF file'),

    # Binary Documents
    'application/pdf' => _('PDF file'),

    # Images
    'image/tiff' => _('TIFF image'),

    # Word Processing
    'application/vnd.ms-word' => _('Word document'),
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => _('Word document'),

    # Presentation
    'application/vnd.ms-powerpoint' => _('PowerPoint presentation'),
    'application/vnd.openxmlformats-officedocument.presentationml.presentation' => _('PowerPoint presentation'),

    # Spreadsheet
    'application/vnd.ms-excel' => _('Excel spreadsheet'),
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => _('Excel spreadsheet')
  }.freeze
  # rubocop:enable Layout/LineLength

  included do
    scope :binary, -> { where.not(content_type: AlaveteliTextMasker::TextMask) }

    validates_presence_of :content_type

    cattr_reader :content_type_names, default: CONTENT_TYPE_NAMES
  end

  # Name of type of attachment type - only valid for things with a HTML viewer.
  def name_of_content_type
    content_type_names[content_type]
  end

  def text_type?
    AlaveteliTextMasker::TextMask.include?(content_type)
  end
end
