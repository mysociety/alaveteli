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
        next 0 unless sheet.is_a?(RubyXL::Worksheet)

        hidden_columns = []

        sheet.cols.compact.select(&:hidden).each do |col_range|
          hidden_columns += (col_range.min..col_range.max).to_a
        end

        hidden_columns.count do |c|
          cells = sheet.sheet_data.rows.compact.map { _1[c - 1] }
          cells.compact.any? { !_1.value.to_s.empty? }
        end
      end
    end

    def hidden_rows
      workbook.worksheets.sum do |sheet|
        next 0 unless sheet.is_a?(RubyXL::Worksheet)

        hidden_rows = sheet.sheet_data.rows.compact.select(&:hidden)

        hidden_rows.count do |row|
          cells = row.cells
          cells.compact.any? { !_1.value.to_s.empty? }
        end
      end
    end

    def hidden_sheets
      workbook.sheets.count do |sheet|
        sheet.state && sheet.state != 'visible'
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
