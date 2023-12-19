require "active_storage"
require "active_storage/analyzer"

require "excel_analyzer/probe"

module ExcelAnalyzer
  ##
  # The Analyzer class is responsible for analyzing Excel (.xlsx) files uploaded
  # through Active Storage.
  #
  class XlsxAnalyzer < ActiveStorage::Analyzer
    include ExcelAnalyzer::Probe

    CONTENT_TYPE =
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

    def self.accept?(blob)
      blob.content_type == CONTENT_TYPE
    end

    def metadata
      { excel: excel_metadata }
    end

    private

    def excel_metadata
      download_blob_to_tempfile(&method(:probe))
    rescue StandardError => ex
      { error: ex.message }
    end
  end
end
