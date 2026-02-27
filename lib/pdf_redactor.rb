require 'tempfile'
require 'rexml/document'

module PdfRedactor
  RedactionResult = Struct.new(
    :pdf_data,
    :matched_rules,
    :unmatched_rules,
    :warnings,
    :strategy,
    keyword_init: true
  ) do
    def success?
      strategy != :failed
    end
  end

  BBoxWord = Struct.new(:text, :x1, :y1, :x2, :y2, :page, keyword_init: true)

  MatchRegion = Struct.new(
    :page, :x1, :y1, :x2, :y2, :rule, :matched_text, keyword_init: true
  )

  module_function

  # Main entry point. Returns a RedactionResult or nil on total failure.
  #
  # pdf_data     - raw PDF bytes (String)
  # censor_rules - array of CensorRule objects
  # masks        - array of {to_replace:, replacement:} hashes
  def redact(pdf_data, censor_rules: [], masks: [])
    warnings = []

    # Step 1: Extract text with bounding boxes
    bbox_data = extract_bbox_words(pdf_data)
    if bbox_data.nil?
      warnings << 'pdftotext bbox extraction failed'
      return RedactionResult.new(
        pdf_data: nil,
        matched_rules: [],
        unmatched_rules: censor_rules.map { |r| r.respond_to?(:id) ? r.id : r.to_s },
        warnings: warnings,
        strategy: :failed
      )
    end

    # Step 2: Find matches
    matches, matched_rule_ids, unmatched_rule_ids =
      find_matches(bbox_data, censor_rules, masks)

    if matches.empty?
      return RedactionResult.new(
        pdf_data: pdf_data,
        matched_rules: [],
        unmatched_rules: unmatched_rule_ids,
        warnings: warnings,
        strategy: :unchanged
      )
    end

    # Step 3: Apply redaction with HexaPDF
    result_pdf, redaction_warnings, strategy =
      redact_with_hexapdf(pdf_data, matches)

    warnings.concat(redaction_warnings)

    if result_pdf.nil?
      return RedactionResult.new(
        pdf_data: nil,
        matched_rules: matched_rule_ids,
        unmatched_rules: unmatched_rule_ids,
        warnings: warnings + ['HexaPDF redaction failed completely'],
        strategy: :failed
      )
    end

    RedactionResult.new(
      pdf_data: result_pdf,
      matched_rules: matched_rule_ids,
      unmatched_rules: unmatched_rule_ids,
      warnings: warnings,
      strategy: strategy
    )
  rescue StandardError => e
    Rails.logger.error("PdfRedactor.redact failed: #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.first(10).join("\n"))
    nil
  end

  # Runs pdftotext -bbox-layout and parses the XHTML output.
  # Returns { page_num => [BBoxWord, ...] } or nil on failure.
  def extract_bbox_words(pdf_data)
    temp = Tempfile.new(['pdfredact', '.pdf'], './tmp', encoding: 'ascii-8bit')
    temp.write(pdf_data)
    temp.close

    output = AlaveteliExternalCommand.run(
      'pdftotext', '-bbox-layout', temp.path, '-',
      timeout: 30
    )

    return nil if output.blank?

    parse_bbox_xhtml(output)
  rescue StandardError => e
    Rails.logger.error(
      "PdfRedactor.extract_bbox_words failed: #{e.class}: #{e.message}"
    )
    nil
  ensure
    temp&.unlink
  end

  # Parses the XHTML output from pdftotext -bbox-layout.
  # Returns { page_num => [BBoxWord, ...] }
  def parse_bbox_xhtml(xhtml)
    result = {}
    doc = REXML::Document.new(xhtml)

    pages = REXML::XPath.match(doc, '//page')
    pages.each_with_index do |page_elem, idx|
      page_num = idx + 1
      words = []

      REXML::XPath.match(page_elem, './/word').each do |word_elem|
        text = word_elem.text.to_s
        next if text.strip.empty?

        words << BBoxWord.new(
          text: text,
          x1: word_elem.attributes['xMin'].to_f,
          y1: word_elem.attributes['yMin'].to_f,
          x2: word_elem.attributes['xMax'].to_f,
          y2: word_elem.attributes['yMax'].to_f,
          page: page_num
        )
      end

      result[page_num] = words
    end

    result
  end

  # Finds matches for censor rules and masks against extracted text.
  # Returns [matches, matched_rule_ids, unmatched_rule_ids]
  def find_matches(bbox_data, censor_rules, masks)
    all_matches = []
    matched_rule_ids = Set.new
    all_rule_ids = Set.new

    # Build matchers from censor rules
    matchers = censor_rules.map do |rule|
      rule_id = rule.respond_to?(:id) ? rule.id : rule.to_s
      all_rule_ids << rule_id
      pattern = rule.respond_to?(:regexp?) && rule.regexp? ?
        Regexp.new(rule.text, Regexp::MULTILINE) :
        Regexp.new(Regexp.escape(rule.respond_to?(:text) ? rule.text : rule.to_s))
      { id: rule_id, pattern: pattern }
    end

    # Build matchers from masks (to_replace can be String or Regexp)
    masks.each do |mask|
      pattern = mask[:to_replace].is_a?(Regexp) ?
        mask[:to_replace] :
        Regexp.new(Regexp.escape(mask[:to_replace].to_s))
      matchers << { id: "mask:#{mask[:to_replace]}", pattern: pattern }
      all_rule_ids << "mask:#{mask[:to_replace]}"
    end

    bbox_data.each do |page_num, words|
      next if words.empty?

      # Concatenate words with spaces, tracking character offset -> word index
      text = ''
      char_to_word_indices = []

      words.each_with_index do |word, idx|
        unless text.empty?
          text << ' '
          char_to_word_indices << nil # space doesn't belong to a word
        end
        word.text.each_char do
          text << _1
          char_to_word_indices << idx
        end
      end

      # Run each matcher against the concatenated text
      matchers.each do |matcher|
        text.scan(matcher[:pattern]) do
          match = Regexp.last_match
          match_start = match.begin(0)
          match_end = match.end(0) - 1

          # Find which words are covered by this match
          word_indices = char_to_word_indices[match_start..match_end]
            .compact.uniq

          next if word_indices.empty?

          matched_rule_ids << matcher[:id]

          # Compute the union bounding box of all matched words
          matched_words = word_indices.map { |i| words[i] }
          region = MatchRegion.new(
            page: page_num,
            x1: matched_words.map(&:x1).min,
            y1: matched_words.map(&:y1).min,
            x2: matched_words.map(&:x2).max,
            y2: matched_words.map(&:y2).max,
            rule: matcher[:id],
            matched_text: match[0]
          )
          all_matches << region
        end
      end
    end

    unmatched_rule_ids = (all_rule_ids - matched_rule_ids).to_a
    [all_matches, matched_rule_ids.to_a, unmatched_rule_ids]
  end

  # Applies redaction using HexaPDF to draw black rectangles, then flattens
  # redacted pages by rendering them as images so the underlying text can't
  # be selected or copied.
  #
  # Non-redacted pages are left untouched (text remains selectable/accessible).
  #
  # Returns [pdf_data, warnings, strategy]
  def redact_with_hexapdf(pdf_data, matches)
    require 'hexapdf'

    warnings = []
    strategy = :flattened

    # Group matches by page
    matches_by_page = matches.group_by(&:page)

    # Step 1: Draw black rectangles on redacted pages
    doc = HexaPDF::Document.new(io: StringIO.new(pdf_data))

    matches_by_page.each do |page_num, page_matches|
      page_index = page_num - 1
      page = doc.pages[page_index]
      next unless page

      draw_redaction_rectangles(page, page_matches)
    end

    # Step 2: Write intermediate PDF (rectangles drawn, text still underneath)
    intermediate_io = StringIO.new(''.b)
    doc.write(intermediate_io)
    intermediate_pdf = intermediate_io.string

    # Step 3: Flatten each redacted page by rendering it as an image.
    # This bakes the black rectangles into a raster — the text underneath
    # becomes part of the image and can't be selected or copied.
    final_doc = HexaPDF::Document.new(io: StringIO.new(intermediate_pdf))

    # Collect page dimensions to avoid re-parsing the PDF in render_page_to_pdf
    page_dimensions = {}
    doc.pages.each_with_index do |pg, idx|
      box = pg.box(:media)
      page_dimensions[idx + 1] = [box.width, box.height]
    end

    # Write intermediate PDF to disk once for pdftocairo to use
    intermediate_temp = Tempfile.new(
      ['pdfredact_intermediate', '.pdf'], './tmp', encoding: 'ascii-8bit'
    )
    intermediate_temp.write(intermediate_pdf)
    intermediate_temp.close

    matches_by_page.each_key do |page_num|
      begin
        dims = page_dimensions[page_num]
        image_pdf = render_page_to_pdf(
          intermediate_temp.path, page_num,
          page_width: dims&.first, page_height: dims&.last
        )
        if image_pdf
          replace_page_with_image(final_doc, page_num, image_pdf)
        else
          warnings << "Failed to flatten page #{page_num} as image"
          strategy = :mixed
        end
      rescue StandardError => e
        warnings << "Failed to flatten page #{page_num}: " \
                     "#{e.class}: #{e.message}"
        strategy = :mixed
      end
    end

    intermediate_temp.unlink

    output = StringIO.new(''.b)
    final_doc.write(output)
    [output.string, warnings, strategy]
  rescue StandardError => e
    Rails.logger.error(
      "PdfRedactor.redact_with_hexapdf failed: #{e.class}: #{e.message}"
    )
    [nil, ["HexaPDF processing failed: #{e.message}"], :failed]
  end

  # Draws filled black rectangles at each match region on the page.
  def draw_redaction_rectangles(page, page_matches)
    canvas = page.canvas(type: :overlay)
    canvas.fill_color(0, 0, 0) # black

    page_height = page.box(:media).height

    page_matches.each do |region|
      # pdftotext coordinates: origin top-left, y increases downward
      # PDF coordinates: origin bottom-left, y increases upward
      x = region.x1
      y = page_height - region.y2
      width = region.x2 - region.x1
      height = region.y2 - region.y1

      # Add small padding for safety
      padding = 1
      canvas.rectangle(
        x - padding, y - padding,
        width + (2 * padding), height + (2 * padding)
      )
    end

    canvas.fill
  end

  # Renders a single page of the given PDF as a PNG, then embeds that PNG
  # into a new single-page PDF using HexaPDF at the original page dimensions.
  # The input PDF should already have redaction rectangles drawn so they get
  # baked into the raster.
  #
  # pdf_path - path to the intermediate PDF on disk
  def render_page_to_pdf(pdf_path, page_num, page_width: nil, page_height: nil)
    png_temp = Tempfile.new(
      ['pdfredact_page', '.png'], './tmp', encoding: 'ascii-8bit'
    )
    png_temp.close

    # Render the specific page to PNG at 200 DPI
    AlaveteliExternalCommand.run(
      'pdftocairo', '-png', '-r', '200', '-singlefile',
      '-f', page_num.to_s, '-l', page_num.to_s,
      pdf_path, png_temp.path.sub(/\.png$/, ''),
      timeout: 60
    )

    png_path = png_temp.path
    return nil unless File.exist?(png_path) && File.size(png_path) > 0

    # Get page dimensions from the source PDF if not provided
    unless page_width && page_height
      src_doc = HexaPDF::Document.new(io: File.open(pdf_path, 'rb'))
      src_page = src_doc.pages[page_num - 1]
      media_box = src_page.box(:media)
      page_width = media_box.width
      page_height = media_box.height
    end

    # Create a new single-page PDF with the PNG embedded at the original
    # page dimensions using HexaPDF
    image_doc = HexaPDF::Document.new
    page = image_doc.pages.add([0, 0, page_width, page_height])
    canvas = page.canvas
    canvas.image(png_path, at: [0, 0], width: page_width, height: page_height)

    output = StringIO.new(''.b)
    image_doc.write(output)
    output.string
  ensure
    png_temp&.unlink
  end

  # Replaces a page in the HexaPDF document with an image-based PDF page.
  def replace_page_with_image(doc, page_num, image_pdf_data)
    image_doc = HexaPDF::Document.new(io: StringIO.new(image_pdf_data))
    image_page = image_doc.pages[0]
    return unless image_page

    page_index = page_num - 1
    original_page = doc.pages[page_index]

    # Replace the page's content and resources with the image version
    original_page[:Contents] = doc.import(image_page[:Contents])
    original_page[:Resources] = doc.import(image_page[:Resources])
    original_page[:MediaBox] = image_page[:MediaBox]&.dup
  end
end
