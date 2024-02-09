require "excel_analyzer/eml_analyzer"
require "excel_analyzer/xls_analyzer"
require "excel_analyzer/xlsx_analyzer"
require "excel_analyzer/railtie" if defined?(Rails)

##
# This module provides functionality to analyze Excel files, particularly to
# detect hidden data within spreadsheet attachments in emails. It supports .xls
# and .xlsx file formats.
module ExcelAnalyzer
  # A configurable callable that gets executed when an email with a spreadsheet
  # attachment is analyzed. This allows for custom handling of the spreadsheet
  # data.
  #
  # @example Set a custom callable to handle received spreadsheets
  #   ExcelAnalyzer.on_spreadsheet_received = ->(blob) { process(blob) }
  #
  # @!attribute [rw] on_spreadsheet_received
  # @return [Proc] the callable to run for spreadsheet attachments
  mattr_accessor :on_spreadsheet_received, default: ->(blob) {}

  # Provides the list of content types that the ExcelAnalyzer will attempt to
  # analyze in search of hidden data. It currently includes content types for
  # .xls and .xlsx files.
  #
  # @return [Array<String>] the list of supported spreadsheet content types
  def self.content_types
    [XlsAnalyzer::CONTENT_TYPE, XlsxAnalyzer::CONTENT_TYPE]
  end
end
