require "rubyXL"

module ExcelAnalyzer
  ##
  # It checks for various features within the Excel (.xlsx) file such as
  # hidden rows, columns, sheets, pivot caches, and external links.
  #
  # The class uses Nokogiri for parsing the contents.
  #
  class Metadata
    attr_reader :file, :workbook

    def initialize(file)
      @file = file
      @root = RubyXL::WorkbookRoot.parse_zip_file(file)
      @workbook = @root.workbook
    end

    def to_h
      {
        data_model: data_model,
        external_links: external_links,
        hidden_columns: hidden_columns,
        hidden_rows: hidden_rows,
        hidden_sheets: hidden_sheets,
        named_ranges: named_ranges,
        pivot_cache: pivot_cache
      }
    end

    private

    def data_model
      file.glob("xl/model/*").count
    end

    def external_links
      workbook.external_references&.count || 0
    end

    def hidden_columns
      workbook.worksheets.sum do |sheet|
        sheet.cols.compact.select(&:hidden).sum { _1.max - _1.min + 1 }
      end
    end

    def hidden_rows
      workbook.worksheets.sum do |sheet|
        sheet.sheet_data.rows.compact.count(&:hidden)
      end
    end

    def hidden_sheets
      workbook.sheets.count do |sheet|
        sheet.state != 'visible'
      end
    end

    def pivot_cache
      workbook.pivot_caches&.count || 0
    end

    def named_ranges
      workbook.defined_names&.count || 0
    end
  end
end
