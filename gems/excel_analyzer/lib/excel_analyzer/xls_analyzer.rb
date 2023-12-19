require "open3"
require "tempfile"
require "tmpdir"

require "active_storage"
require "active_storage/analyzer"

require "excel_analyzer/probe"

module ExcelAnalyzer
  ##
  # The Analyzer class is responsible for analyzing Excel (.xls) files uploaded
  # through Active Storage.
  #
  # Files are first converted to XLSX format and then probed for hidden data.
  #
  class XlsAnalyzer < ActiveStorage::Analyzer
    include ExcelAnalyzer::Probe

    CONTENT_TYPE = "application/vnd.ms-excel"

    def self.accept?(blob)
      blob.content_type == CONTENT_TYPE
    end

    def metadata
      { excel: excel_metadata }
    end

    private

    def excel_metadata
      download_blob_to_tempfile(&method(:convert_and_probe))
    rescue StandardError => ex
      { error: ex.message }
    end

    def convert_and_probe(io)
      probe(convert(io))
    end

    def convert(io)
      raise 'LibreOffice (soffice) command not found' unless soffice_installed?

      Dir.mktmpdir do |tmpdir|
        _stdout, _stderr, status = Open3.capture3(
          "soffice --headless --convert-to xlsx --outdir #{tmpdir} #{io.path}"
        )

        path = File.join(tmpdir, File.basename(io.path, ".*") + ".xlsx")

        if !status.success? || !File.exist?(path)
          raise "LibreOffice conversion failed"
        end

        Tempfile.new.tap do |tempfile|
          tempfile.write(File.read(path))
          tempfile.rewind
        end
      end
    end

    def soffice_installed?
      system("which soffice > /dev/null 2>&1")
    end
  end
end
