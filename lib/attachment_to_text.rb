# Extracts text from the masked body of an FoiAttachment for search indexing
class AttachmentToText
  WORD_DOCS = %w[
    application/vnd.ms-word
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
  ]

  POWERPOINT_DOCS = %w[
    application/vnd.ms-powerpoint
    application/vnd.openxmlformats-officedocument.presentationml.presentation
  ]

  EXCEL_DOCS = %w[
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  ]

  # Temporary compatibility interface
  def self.from_part(part, text)
    interface = OpenStruct.new(
      content_type: part.content_type,
      default_body: text,
      charset: 'UTF-8'
    )

    new(interface)
  end

  # Temporary compatibility interface
  def self.from_string(str, content_type: 'text/plain')
    interface = OpenStruct.new(
      content_type: content_type,
      default_body: str,
      charset: 'UTF-8'
    )

    new(interface)
  end

  def initialize(attachment)
    @attachment = attachment
  end

  def to_text
    text = get_attachment_text_one_file(
      attachment.content_type,
      attachment.default_body,
      attachment.charset
    )

    convert_string_to_utf8(text, 'UTF-8').string
  end

  protected

  attr_reader :attachment

  private

  def get_attachment_text_one_file(content_type, body, charset = 'utf-8')
    # NOTE: re. charset: TMail always tries to convert email bodies
    # to UTF8 by default, so normally it should already be that.
    # TODO: - tell all these command line tools to return utf-8
    if WORD_DOCS.include?(content_type)
      extract_ms_word(body)
    elsif POWERPOINT_DOCS.include?(content_type)
      extract_ms_powerpoint(body)
    elsif EXCEL_DOCS.include?(content_type)
      extract_ms_excel(body)
    elsif content_type == 'application/rtf'
      extract_rtf(body)
    elsif content_type == 'text/plain'
      extract_plain(body)
    elsif content_type == 'text/html'
      extract_html(body)
    elsif content_type == 'application/pdf'
      extract_pdf(body)
    elsif content_type == 'application/zip'
      extract_zip(body)
    else
      ''
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
        timeout: 1200,
        env: { 'LANG' => 'C' }
      )
    end
  end

  def extract_rtf(body)
    extract_ms_word(body)
  end

  def extract_pdf(body)
    with_tempfile(body) do |file|
      AlaveteliExternalCommand.run(
        'pdftotext',
        file.path,
        '-',
        binary_output: false,
        timeout: 1200,
      )
    end
  end

  def extract_ms_word(body)
    with_tempfile(body) do |file|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          AlaveteliExternalCommand.run(
            'libreoffice', '--headless',
            '--convert-to', 'txt:Text (encoded):UTF8',
            file.path,
            binary_output: false,
            timeout: 1200
          )

          File.read("#{ File.basename(file.path) }.txt")
        end
      end
    end
  end

  def extract_ms_powerpoint(body)
    with_tempfile(body) do |file|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          AlaveteliExternalCommand.run(
            'libreoffice', '--headless',
            '--convert-to', 'pdf',
            file.path,
            binary_output: false,
            timeout: 1200
          )

          pdf = "#{ File.basename(file.path) }.pdf"

          AlaveteliExternalCommand.run(
            'pdftotext', pdf, '-', binary_output: false, timeout: 1200
          )
        end
      end
    end
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
  def extract_ms_excel(body)
    csv_filters = '(StarCalc):44,34,76,1,,0,false,true,false,false,,-1'

    with_tempfile(body) do |file|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          AlaveteliExternalCommand.run(
            'libreoffice', '--headless',
            '--convert-to', "csv:Text - txt - csv #{csv_filters}",
            file.path,
            binary_output: false,
            timeout: 1200
          )

          combine_csv_files_with_sheet_names(file)
        end
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
        text += get_attachment_text_from_zip_file(zip_file)
        zip_file.close
      end
    rescue
      $stderr.puts("Error processing zip file: #{$ERROR_INFO.inspect}")
    end

    text
  end

  def get_attachment_text_from_zip_file(zip_file)
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
        text += get_attachment_text_one_file(content_type, body)
      end
    end
    text
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
