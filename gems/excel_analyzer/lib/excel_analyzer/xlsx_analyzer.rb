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
      data = excel_metadata

      if suspected_problem?(data)
        # rubocop:disable Style/RescueModifier
        ExcelAnalyzer.on_hidden_metadata.call(blob, data) rescue nil
        # rubocop:enable Style/RescueModifier
      end

      { excel: data }
    end

    private

    def excel_metadata
      download_blob_to_tempfile(&method(:probe))
    rescue StandardError => ex
      { error: ex.message }
    end

    def suspected_problem?(data)
      return true if data[:error]

      total_count = data.sum { |k, v| v }
      return false if total_count == 0
      return false if data[:named_ranges] == total_count
      return false if data[:external_links] == total_count
      return false if data[:hidden_rows] == total_count && total_count <= 50

      true
    end
  end
end
