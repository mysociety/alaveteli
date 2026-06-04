# Deal with the content type of attachments
module FoiAttachment::ContentType
  extend ActiveSupport::Concern

  # rubocop:disable Layout/LineLength
  CONTENT_TYPE_NAMES = {
    # Plain Text
    'text/plain' => _('Text file'),
    'text/csv' => _('CSV file'),
    'text/html' => _('HTML file'),
    'application/rtf' => _('RTF file'),

    # Binary Documents
    'application/pdf' => _('PDF file'),
    'application/zip' => _('Zip file'),

    # Images
    'image/bmp' => _('BMP image'),
    'image/gif' => _('GIF image'),
    'image/jpeg' => _('JPEG image'),
    'image/jpg' => _('JPEG image'),
    'image/png' => _('PNG image'),
    'image/svg+xml' => _('SVG image'),
    'image/tiff' => _('TIFF image'),
    'image/webp' => _('WebP image'),
    'image/x-png' => _('PNG image'),

    # Word Processing
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => _('Word document'),
    'application/vnd.ms-word' => _('Word document'),
    'application/vnd.ms-word.document.macroenabled.12' => _('Word document'),
    'application/vnd.oasis.opendocument.text' => _('Word processing document'),
    'application/vnd.oasis.opendocument.text-template' => _('Word processing document'),
    'application/vnd.oasis.opendocument.text-flat-xml' => _('Word processing document'),
    'application/vnd.sun.xml.writer' => _('Word processing document'),
    'application/vnd.sun.xml.writer.template' => _('Word processing document'),

    # Presentation
    'application/vnd.openxmlformats-officedocument.presentationml.presentation' => _('PowerPoint presentation'),
    'application/vnd.ms-powerpoint' => _('PowerPoint presentation'),
    'application/vnd.ms-powerpoint.presentation.macroenabled.12' => _('PowerPoint presentation'),
    'application/vnd.ms-powerpoint.slideshow.macroenabled.12' => _('PowerPoint presentation'),
    'application/vnd.oasis.opendocument.presentation' => _('Presentation file'),
    'application/vnd.oasis.opendocument.presentation-template' => _('Presentation file'),
    'application/vnd.oasis.opendocument.presentation-flat-xml' => _('Presentation file'),

    # Spreadsheet
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => _('Excel spreadsheet'),
    'application/vnd.ms-excel' => _('Excel spreadsheet'),
    'application/vnd.ms-excel.sheet.macroenabled.12' => _('Excel spreadsheet'),
    'application/vnd.ms-excel.sheet.binary.macroenabled.12' => _('Excel spreadsheet'),
    'application/vnd.oasis.opendocument.spreadsheet' => _('Spreadsheet'),
    'application/vnd.oasis.opendocument.spreadsheet-template' => _('Spreadsheet'),
    'application/vnd.oasis.opendocument.spreadsheet-flat-xml' => _('Spreadsheet'),

    # Email delivery status files
    'message/delivery-status' => _('Email delivery status message')
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
