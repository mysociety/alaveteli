require 'spec_helper'
require 'pdf_redactor'

RSpec.describe PDFRedactor do
  describe '.extract_bbox_words' do
    it 'extracts words with bounding boxes from a PDF' do
      pdf_data = load_file_fixture('tfl.pdf')
      result = described_class.extract_bbox_words(pdf_data)

      expect(result).to be_a(Hash)
      expect(result.keys).not_to be_empty
      expect(result.values.first).to all(be_a(PDFRedactor::BBoxWord))
    end

    it 'returns nil when given invalid data' do
      result = described_class.extract_bbox_words('not a pdf')
      expect(result).to be_nil
    end

    it 'returns page numbers starting from 1' do
      pdf_data = load_file_fixture('tfl.pdf')
      result = described_class.extract_bbox_words(pdf_data)

      expect(result.keys.min).to eq(1)
    end
  end

  describe '.parse_bbox_xhtml' do
    it 'parses pdftotext bbox XHTML output' do
      xhtml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head><title></title></head>
        <body>
        <doc>
          <page width="595" height="842">
            <word xMin="100" yMin="200" xMax="150" yMax="215">Hello</word>
            <word xMin="155" yMin="200" xMax="210" yMax="215">World</word>
          </page>
        </doc>
        </body>
        </html>
      XML

      result = described_class.parse_bbox_xhtml(xhtml)

      expect(result).to be_a(Hash)
      expect(result[1].size).to eq(2)
      expect(result[1][0].text).to eq('Hello')
      expect(result[1][0].x1).to eq(100.0)
      expect(result[1][1].text).to eq('World')
    end
  end

  describe '.find_matches' do
    let(:bbox_data) do
      {
        1 => [
          PDFRedactor::BBoxWord.new(
            text: 'John', x1: 100, y1: 200, x2: 140, y2: 215, page: 1
          ),
          PDFRedactor::BBoxWord.new(
            text: 'Smith', x1: 145, y1: 200, x2: 190, y2: 215, page: 1
          ),
          PDFRedactor::BBoxWord.new(
            text: 'lives', x1: 195, y1: 200, x2: 230, y2: 215, page: 1
          ),
          PDFRedactor::BBoxWord.new(
            text: 'here', x1: 235, y1: 200, x2: 265, y2: 215, page: 1
          )
        ]
      }
    end

    it 'finds simple text matches' do
      rule = double('CensorRule', id: 1, text: 'John', regexp?: false)
      matches, matched, unmatched = described_class.find_matches(
        bbox_data, [rule], []
      )

      expect(matches.size).to eq(1)
      expect(matches.first.matched_text).to eq('John')
      expect(matched).to eq([1])
      expect(unmatched).to be_empty
    end

    it 'finds multi-word matches spanning word boundaries' do
      rule = double('CensorRule', id: 2, text: 'John Smith', regexp?: false)
      matches, matched, _unmatched = described_class.find_matches(
        bbox_data, [rule], []
      )

      expect(matches.size).to eq(1)
      region = matches.first
      expect(region.matched_text).to eq('John Smith')
      # Bounding box should span both words
      expect(region.x1).to eq(100)
      expect(region.x2).to eq(190)
    end

    it 'finds regex matches' do
      rule = double('CensorRule', id: 3, text: 'J[a-z]+n', regexp?: true)
      matches, matched, _unmatched = described_class.find_matches(
        bbox_data, [rule], []
      )

      expect(matches.size).to eq(1)
      expect(matches.first.matched_text).to eq('John')
      expect(matched).to eq([3])
    end

    it 'reports unmatched rules' do
      rule = double(
        'CensorRule', id: 4, text: 'Nonexistent', regexp?: false
      )
      _matches, _matched, unmatched = described_class.find_matches(
        bbox_data, [rule], []
      )

      expect(unmatched).to eq([4])
    end

    it 'matches mask patterns' do
      mask = { to_replace: /\bhere\b/, replacement: '[REDACTED]' }
      matches, _matched, _unmatched = described_class.find_matches(
        bbox_data, [], [mask]
      )

      expect(matches.size).to eq(1)
      expect(matches.first.matched_text).to eq('here')
    end

    it 'handles email mask patterns' do
      email_data = {
        1 => [
          PDFRedactor::BBoxWord.new(
            text: 'contact', x1: 100, y1: 200, x2: 150, y2: 215, page: 1
          ),
          PDFRedactor::BBoxWord.new(
            text: 'user@example.com', x1: 155, y1: 200, x2: 280, y2: 215,
            page: 1
          )
        ]
      }

      mask = { to_replace: /[\w.+-]+@[\w.-]+\.\w+/, replacement: '[email]' }
      matches, _matched, _unmatched = described_class.find_matches(
        email_data, [], [mask]
      )

      expect(matches.size).to eq(1)
      expect(matches.first.matched_text).to eq('user@example.com')
    end

    it 'returns empty matches when nothing matches' do
      rule = double('CensorRule', id: 5, text: 'zebra', regexp?: false)
      matches, matched, unmatched = described_class.find_matches(
        bbox_data, [rule], []
      )

      expect(matches).to be_empty
      expect(matched).to be_empty
      expect(unmatched).to eq([5])
    end
  end

  describe '.redact' do
    context 'with a real PDF' do
      let(:pdf_data) { load_file_fixture('tfl.pdf') }

      it 'returns a RedactionResult' do
        rule = FactoryBot.build(
          :censor_rule, text: 'foi@tfl.gov.uk', replacement: '[REDACTED]'
        )
        result = described_class.redact(
          pdf_data, censor_rules: [rule], masks: []
        )

        expect(result).to be_a(PDFRedactor::RedactionResult)
        expect(result.pdf_data).to be_present
        expect(result.strategy).to be_in([:flattened, :mixed])
      end

      it 'returns original PDF when no rules match' do
        rule = FactoryBot.build(
          :censor_rule, text: 'zzz_nonexistent_zzz',
                        replacement: '[REDACTED]'
        )
        result = described_class.redact(
          pdf_data, censor_rules: [rule], masks: []
        )

        expect(result.pdf_data).to eq(pdf_data)
        expect(result.matched_rules).to be_empty
      end

      it 'removes matched text from the redacted PDF' do
        rule = FactoryBot.build(
          :censor_rule, text: 'foi@tfl.gov.uk', replacement: '[REDACTED]'
        )
        result = described_class.redact(
          pdf_data, censor_rules: [rule], masks: []
        )

        # Extract text from the redacted PDF using pdftotext
        temp = Tempfile.new(
          ['redacted', '.pdf'], './tmp', encoding: 'ascii-8bit'
        )
        temp.write(result.pdf_data)
        temp.close

        extracted = AlaveteliExternalCommand.run(
          'pdftotext', temp.path, '-', timeout: 30
        )
        temp.unlink

        if extracted.nil?
          skip 'pdftotext not available'
        else
          expect(extracted).not_to include('foi@tfl.gov.uk')
        end
      end

      it 'reports matched and unmatched rules' do
        matching_rule = FactoryBot.build(
          :censor_rule, id: 10, text: 'foi@tfl.gov.uk',
                        replacement: '[REDACTED]'
        )
        non_matching_rule = FactoryBot.build(
          :censor_rule, id: 11, text: 'zzz_nonexistent_zzz',
                        replacement: '[REDACTED]'
        )

        result = described_class.redact(
          pdf_data,
          censor_rules: [matching_rule, non_matching_rule],
          masks: []
        )

        expect(result.matched_rules).to include(10)
        expect(result.unmatched_rules).to include(11)
      end
    end

    context 'with invalid PDF data' do
      it 'returns a failed result' do
        rule = FactoryBot.build(
          :censor_rule, text: 'test', replacement: '[REDACTED]'
        )
        result = described_class.redact(
          'not a pdf', censor_rules: [rule], masks: []
        )

        expect(result).to be_a(PDFRedactor::RedactionResult)
        expect(result.strategy).to eq(:failed)
        expect(result.pdf_data).to be_nil
      end
    end

    context 'with regex censor rules' do
      let(:pdf_data) { load_file_fixture('tfl.pdf') }

      it 'matches regex patterns' do
        rule = FactoryBot.build(
          :censor_rule, text: 'foi@[a-z]+\.gov\.uk',
                        replacement: '[REDACTED]', regexp: true
        )
        result = described_class.redact(
          pdf_data, censor_rules: [rule], masks: []
        )

        expect(result.matched_rules).not_to be_empty
      end
    end
  end

  describe '.render_page_to_pdf' do
    it 'renders a page as an image-based PDF' do
      pdf_data = load_file_fixture('tfl.pdf')
      temp = Tempfile.new(['test', '.pdf'], './tmp', encoding: 'ascii-8bit')
      temp.write(pdf_data)
      temp.close

      result = described_class.render_page_to_pdf(temp.path, 1)
      temp.unlink

      if result
        # If the system tools are available, verify we got PDF data
        expect(result).to start_with('%PDF')
      else
        # pdftocairo not available — skip gracefully
        skip 'pdftocairo not available'
      end
    end
  end

  describe PDFRedactor::RedactionResult do
    it 'reports success for flattened strategy' do
      result = described_class.new(
        pdf_data: 'data', matched_rules: [1], unmatched_rules: [],
        warnings: [], strategy: :flattened
      )
      expect(result.success?).to be true
    end

    it 'reports success for unchanged strategy' do
      result = described_class.new(
        pdf_data: 'data', matched_rules: [], unmatched_rules: [],
        warnings: [], strategy: :unchanged
      )
      expect(result.success?).to be true
    end

    it 'reports success for mixed strategy' do
      result = described_class.new(
        pdf_data: 'data', matched_rules: [1], unmatched_rules: [],
        warnings: ['page 2 fell back to image'], strategy: :mixed
      )
      expect(result.success?).to be true
    end

    it 'reports failure for failed strategy' do
      result = described_class.new(
        pdf_data: nil, matched_rules: [], unmatched_rules: [1],
        warnings: ['total failure'], strategy: :failed
      )
      expect(result.success?).to be false
    end
  end
end
