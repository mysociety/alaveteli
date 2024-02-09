require "mail"

require "active_storage"
require "active_storage/analyzer"

require "mail_handler"

module ExcelAnalyzer
  ##
  # The EmlAnalyzer class extends the ActiveStorage::Analyzer to define a custom
  # analysis process for EML files. It checks for the presence of attachments
  # with content types associated with spreadsheet formats and invokes a
  # callback if necessary.
  class EmlAnalyzer < ActiveStorage::Analyzer
    CONTENT_TYPE = "message/rfc822"

    def self.accept?(blob)
      blob.content_type == CONTENT_TYPE
    end

    def metadata
      download_blob_to_tempfile do |file|
        mail = Mail.read(file.path)

        content_types = MailHandler.get_attachment_attributes(mail).map do
          _1[:content_type]
        end

        if content_types.any? { ExcelAnalyzer.content_types.include?(_1) }
          # rubocop:disable Style/RescueModifier
          ExcelAnalyzer.on_spreadsheet_received.call(blob) rescue nil
          # rubocop:enable Style/RescueModifier
        end
      end

      {}
    end
  end
end
