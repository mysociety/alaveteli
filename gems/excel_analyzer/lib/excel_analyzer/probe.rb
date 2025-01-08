require "zip"

require "excel_analyzer/metadata"

module ExcelAnalyzer
  ##
  # Probe an Excel (.xlsx) IO object and return metadata with information about
  # the file.
  #
  # The module uses rubyzip for reading the contents.
  #
  module Probe
    def probe(io)
      Zip::File.open(io.path) do |zip_file|
        Metadata.new(zip_file).to_h
      end
    end
  end
end
