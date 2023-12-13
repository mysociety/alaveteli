require "active_storage"
require "active_storage/analyzer"
require "nokogiri"
require "zip"

module ExcelAnalyzer
  ##
  # The Analyzer class is responsible for analyzing Excel files uploaded through
  # Active Storage. It checks for various features within the Excel file such as
  # hidden rows, columns, sheets, pivot caches, and external links.
  #
  # The class uses rubyzip and Nokogiri for reading and parsing the contents of
  # the Excel (.xlsx) files.
  #
  class Analyzer < ActiveStorage::Analyzer
    XLSX_CONTENT_TYPE =
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

    def self.accept?(blob)
      blob.content_type == XLSX_CONTENT_TYPE
    end

    def metadata
      { excel: excel_metadata }
    end

    private

    def excel_metadata
      download_blob_to_tempfile(&method(:probe))
    end

    def probe(tempfile)
      Zip::File.open(tempfile.path) do |zip_file|
        {
          pivot_cache: zip_file.glob("xl/pivotCache/*").any?,
          external_links: zip_file.glob("xl/externalLinks/*").any?,
          hidden_rows: hidden_rows?(zip_file),
          hidden_columns: hidden_columns?(zip_file),
          hidden_sheets: hidden_sheets?(zip_file)
        }
      end

    rescue StandardError => ex
      { error: ex.message }
    end

    def namespace
      { "ns" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main" }
    end

    def hidden?(object)
      object.attr("hidden") == "true" ||
        object.attr("hidden") == "1" ||
        object.attr("state") == "hidden"
    end

    def hidden_rows?(zip_file)
      zip_file.glob("xl/worksheets/*.xml").any? do |worksheet_file|
        doc = Nokogiri::XML(worksheet_file.get_input_stream.read)
        doc.xpath("//ns:row", namespace).any?(&method(:hidden?))
      end
    end

    def hidden_columns?(zip_file)
      zip_file.glob("xl/worksheets/*.xml").any? do |worksheet_file|
        doc = Nokogiri::XML(worksheet_file.get_input_stream.read)
        doc.xpath("//ns:col", namespace).any?(&method(:hidden?))
      end
    end

    def hidden_sheets?(zip_file)
      workbook_file = zip_file.glob("xl/workbook.xml").first
      return false unless workbook_file

      doc = Nokogiri::XML(workbook_file.get_input_stream.read)
      doc.xpath("//ns:sheet", namespace).any?(&method(:hidden?))
    end
  end
end
