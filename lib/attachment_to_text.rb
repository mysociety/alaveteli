# Extracts text from the masked body of an FoiAttachment for search indexing
class AttachmentToText
  MS_WORD_DOCS = %w[
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-word
    application/vnd.ms-word.document.macroenabled.12
  ]

  WORD_PROCESSING_DOCS = %w[
    application/vnd.oasis.opendocument.text
    application/vnd.oasis.opendocument.text-template
    application/vnd.oasis.opendocument.text-flat-xml
    application/vnd.sun.xml.writer
    application/vnd.sun.xml.writer.template
  ]

  MS_POWERPOINT_DOCS = %w[
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/vnd.ms-powerpoint
    application/vnd.ms-powerpoint.presentation.macroenabled.12
    application/vnd.ms-powerpoint.slideshow.macroenabled.12
  ]

  PRESENTATION_DOCS = %w[
    application/vnd.oasis.opendocument.presentation
    application/vnd.oasis.opendocument.presentation-template
    application/vnd.oasis.opendocument.presentation-flat-xml
  ]

  MS_EXCEL_DOCS = %w[
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.ms-excel
    application/vnd.ms-excel.sheet.macroenabled.12
    application/vnd.ms-excel.sheet.binary.macroenabled.12
  ]

  SPREADSHEET_DOCS = %w[
    application/vnd.oasis.opendocument.spreadsheet
    application/vnd.oasis.opendocument.spreadsheet-template
    application/vnd.oasis.opendocument.spreadsheet-flat-xml
  ]

  # Temporary compatibility interface
  def self.from_part(part, text)
    interface = OpenStruct.new(
      content_type: part.content_type,
      default_body: text
    )

    new(interface)
  end

  # Temporary compatibility interface
  def self.from_string(str, content_type: 'text/plain')
    interface = OpenStruct.new(
      content_type: content_type,
      default_body: str
    )

    new(interface)
  end

  def initialize(attachment)
    @attachment = attachment
  end

  def to_text
    text = extract_text(attachment.default_body, attachment.content_type)
    convert_string_to_utf8(text, 'UTF-8').string
  end

  protected

  attr_reader :attachment

  private

  def extract_text(body, content_type)
    # NOTE: re. charset: TMail always tries to convert email bodies
    # to UTF8 by default, so normally it should already be that.
    # TODO: - tell all these command line tools to return utf-8
    case content_type
    when 'text/plain'          then extract_plain(body)
    when 'text/html'           then extract_html(body)
    when 'application/pdf'     then extract_pdf(body)
    when *MS_WORD_DOCS         then extract_ms_word(body)
    when *WORD_PROCESSING_DOCS then extract_word_processing(body)
    when *MS_EXCEL_DOCS        then extract_ms_excel(body)
    when *SPREADSHEET_DOCS     then extract_spreadsheet(body)
    when *MS_POWERPOINT_DOCS   then extract_ms_powerpoint(body)
    when *PRESENTATION_DOCS    then extract_presentation(body)
    when 'application/rtf'     then extract_rtf(body)
    when 'application/zip'     then extract_zip(body)
    when /\Atext\//            then extract_plain(body)
    else ''
    end
  end

  def extract_plain(body)
    body + "\n\n"
  end

  def extract_html(body, charset: 'utf-8')
    with_tempfile(body) do |file|
      # lynx wordwraps links in its output, which then don't
      # get formatted properly by Alaveteli. We use elinks
      # instead, which doesn't do that.
      AlaveteliExternalCommand.run(
        'elinks',
        '-eval', "set document.codepage.assume = \"#{charset}\"",
        '-eval', 'set document.codepage.force_assumed = 1',
        '-dump-charset', 'utf-8',
        '-force-html', '-dump',
        file.path,
        binary_output: false,
        timeout: 5.minutes,
        env: { 'LANG' => 'C' }
      )
    end
  end

  def extract_rtf(body)
    extract_word_processing(body)
  end

  def extract_pdf(body)
    with_tempfile(body) do |file|
      AlaveteliExternalCommand.run(
        'pdftotext',
        file.path,
        '-',
        binary_output: false,
        timeout: 5.minutes,
      )
    end
  end

  def extract_ms_word(body)
    extract_word_processing(body)
  end

  def extract_word_processing(body)
    with_tempfile(body) do |file|
      in_tempdir do
        AlaveteliExternalCommand.run(
          'libreoffice', '--headless',
          '--convert-to', 'txt:Text (encoded):UTF8',
          file.path,
          binary_output: false,
          timeout: 5.minutes
        )

        File.read("#{ File.basename(file.path) }.txt")
      end
    end
  end

  def extract_ms_powerpoint(body)
    extract_presentation(body)
  end

  def extract_presentation(body)
    with_tempfile(body) do |file|
      in_tempdir do
        AlaveteliExternalCommand.run(
          'libreoffice', '--headless',
          '--convert-to', 'pdf',
          file.path,
          binary_output: false,
          timeout: 5.minutes
        )

        pdf = "#{ File.basename(file.path) }.pdf"

        AlaveteliExternalCommand.run(
          'pdftotext', pdf, '-', binary_output: false, timeout: 5.minutes
        )
      end
    end
  end

  def extract_ms_excel(body)
    extract_spreadsheet(body)
  end

  # 44 = comma field separator.
  # 34 = double-quote text delimiter.
  # 76 = UTF-8 character set.
  # 1 = start from row 1.
  # empty token 5 = no column-specific format overrides.
  # 0 = default/UI language.
  # false = quoted fields are not forced to text.
  # true = export number cells as numbers.
  # false = do not use "save cell contents as shown"; export underlying values instead.
  # false = do not export formulas; export values.
  # empty token 11 = unused here; token 11 is only for CSV import ("remove spaces").
  # -1 in token 12 = export all sheets to separate files like sample-Sheet1.csv, sample-Sheet2.csv.
  def extract_spreadsheet(body)
    csv_filters = '(StarCalc):44,34,76,1,,0,false,true,false,false,,-1'

    with_tempfile(body) do |file|
      in_tempdir do
        AlaveteliExternalCommand.run(
          'libreoffice', '--headless',
          '--convert-to', "csv:Text - txt - csv #{csv_filters}",
          file.path,
          binary_output: false,
          timeout: 5.minutes
        )

        combine_csv_files_with_sheet_names(file)
      end
    end
  end

  def combine_csv_files_with_sheet_names(tempfile)
    Dir.glob("*.csv").each_with_object('') do |path, memo|
      # Remove the .csv extension and tempfile prefix, leaving the sheet name
      sheet_name =
        File.basename(path, ".csv").
        gsub("#{File.basename(tempfile.path)}-", '')

      content =
        File.read(path, encoding: "UTF-8", invalid: :replace, undef: :replace)

      memo << "=== #{sheet_name} ===\n\n#{content}\n"
    end.chomp
  end

  def extract_zip(body)
    text = ''

    # recurse into zip files
    begin
      with_tempfile(body) do |file|
        zip_file = Zip::File.open(file.path)
        text += extract_zip_file(zip_file)
        zip_file.close
      end
    rescue
      $stderr.puts("Error processing zip file: #{$ERROR_INFO.inspect}")
    end

    text
  end

  def extract_zip_file(zip_file)
    text = ""
    zip_file.each do |entry|
      if entry.file?
        filename = entry.to_s
        begin
          body = entry.get_input_stream.read
        rescue
          # move to next attachment silently if there were problems
          # TODO: really should reduce this to specific exceptions?
          # e.g. password protected
          next
        end
        calc_mime = AlaveteliFileTypes.filename_to_mimetype(filename)
        if calc_mime
          content_type = calc_mime
        else
          content_type = 'application/octet-stream'
        end
        if content_type == 'text/plain' && body.encoding.to_s == 'ASCII-8BIT'
          body = convert_string_to_utf8(body, 'ASCII-8BIT').string
        end
        text += extract_text(body, content_type)
      end
    end
    text
  end

  def in_tempdir
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        yield
      end
    end
  end

  def with_tempfile(body)
    Tempfile.create('foiextract') do |file|
      file.binmode
      file.print(body)
      file.flush
      yield file
    end
  end
end
