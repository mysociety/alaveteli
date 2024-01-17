require "nokogiri"

module ExcelAnalyzer
  ##
  # It checks for various features within the Excel (.xlsx) file such as
  # hidden rows, columns, sheets, pivot caches, and external links.
  #
  # The class uses Nokogiri for parsing the contents.
  #
  class Metadata
    attr_reader :file

    def initialize(file)
      @file = file
    end

    def to_h
      {
        external_links: external_links?,
        hidden_columns: hidden_columns?,
        hidden_rows: hidden_rows?,
        hidden_sheets: hidden_sheets?,
        pivot_cache: pivot_cache?
      }
    end

    private

    def external_links?
      file.glob("xl/externalLinks/*").any?
    end

    def hidden_columns?
      file.glob("xl/worksheets/*.xml").any? do |worksheet_file|
        doc = Nokogiri::XML(worksheet_file.get_input_stream.read)
        doc.xpath("//ns:col", namespace).any?(&method(:hidden?))
      end
    end

    def hidden_rows?
      file.glob("xl/worksheets/*.xml").any? do |worksheet_file|
        doc = Nokogiri::XML(worksheet_file.get_input_stream.read)
        doc.xpath("//ns:row", namespace).any?(&method(:hidden?))
      end
    end

    def hidden_sheets?
      workbook_file = file.glob("xl/workbook.xml").first
      return false unless workbook_file

      doc = Nokogiri::XML(workbook_file.get_input_stream.read)
      doc.xpath("//ns:sheet", namespace).any?(&method(:hidden?))
    end

    def pivot_cache?
      file.glob("xl/pivotCache/*").any?
    end

    def namespace
      { "ns" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main" }
    end

    def hidden?(object)
      object.attr("hidden") == "true" ||
        object.attr("hidden") == "1" ||
        object.attr("state") == "hidden"
    end
  end
end
