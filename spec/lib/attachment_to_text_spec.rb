require 'spec_helper'

RSpec.describe AttachmentToText do
  describe '#to_text' do
    subject { described_class.new(attachment).to_text }

    # Currently handled
    # --------------------------------------------------------------------------

    context 'doc' do
      let(:attachment) do
        FoiAttachment.new(
          content_type: 'application/vnd.ms-word',
          body: load_file_fixture('lorem.doc')
        )
      end
      it { is_expected.to match(/lorem/) }
    end

    context 'docx' do
      let(:attachment) do
        FoiAttachment.new(
          content_type: 'application/vnd.openxmlformats-officedocument.' \
            'wordprocessingml.document',
          body: load_file_fixture('lorem.docx')
        )
      end
      it { is_expected.to match(/lorem/) }
    end

    context 'html' do
      let(:attachment) do
        FoiAttachment.new(
          content_type: 'text/html',
          body: load_file_fixture('interesting.html')
        )
      end

      it { is_expected.to match(/dull/) }

      context 'with UTF-8 characters' do
        let(:attachment) do
          FoiAttachment.new(
            content_type: 'text/html',
            body: '<html><b>foo</b> është'
          )
        end

        it 'retains the UTF-8 characters in the extracted text' do
          is_expected.to match(/është/)
        end
      end
    end

    context 'pdf' do
      let(:attachment) do
        FoiAttachment.new(
          content_type: 'application/pdf',
          body: load_file_fixture('interesting.pdf')
        )
      end
      it { is_expected.to match(/thisisthebody/) }

      context 'when pdf_ocr_threshold is not set' do
        let(:instance) { described_class.new(attachment) }

        before { described_class.pdf_ocr_threshold = nil }

        it 'does not fall back to OCR even when extracted text is empty' do
          allow(instance).to receive(:extract_text_pdf).and_return('')
          expect(instance).not_to receive(:ocr_pdf)
          instance.to_text
        end
      end

      context 'when pdf_ocr_threshold is set' do
        let(:instance) { described_class.new(attachment) }

        around do |example|
          described_class.pdf_ocr_threshold = 100
          example.run
        ensure
          described_class.pdf_ocr_threshold = nil
        end

        context 'when the extracted text length meets the threshold' do
          before do
            allow(instance).to receive(:extract_text_pdf).and_return('a' * 200)
          end

          it 'returns the pdftotext result without OCR' do
            expect(instance).not_to receive(:ocr_pdf)
            instance.to_text
          end
        end

        context 'when the extracted text length is below the threshold' do
          before do
            allow(instance).to receive(:extract_text_pdf).and_return('short')
          end

          it 'falls back to OCR' do
            expect(instance).to receive(:ocr_pdf).and_return('')
            instance.to_text
          end
        end
      end
    end

    context 'ppt' do
      let(:attachment) do
        FoiAttachment.new(
          content_type: 'application/vnd.ms-powerpoint',
          body: load_file_fixture('interesting.ppt')
        )
      end

      it 'includes contents from the first slide' do
        is_expected.to match(/Interesting/)
      end

      it 'includes contents from subsequent slides' do
        is_expected.to match(/Lorem/)
      end
    end

    context 'pptx' do
      let(:attachment) do
        FoiAttachment.new(
          content_type: 'application/vnd.openxmlformats-officedocument.' \
            'presentationml.presentation',
          body: load_file_fixture('interesting.pptx')
        )
      end

      it 'includes contents from the first slide' do
        is_expected.to match(/Interesting/)
      end

      it 'includes contents from subsequent slides' do
        is_expected.to match(/Lorem/)
      end
    end

    context 'rtf' do
      let(:attachment) do
        FoiAttachment.new(
          content_type: 'application/rtf',
          body: load_file_fixture('interesting.rtf')
        )
      end
      it { is_expected.to match(/thisisthebody/) }

      context 'when LibreOffice writes no output' do
        before do
          allow(AlaveteliExternalCommand).to receive(:run).and_return(nil)
        end

        it { is_expected.to eq('') }
      end
    end

    context 'txt' do
      let(:attachment) do
        FoiAttachment.new(
          content_type: 'text/plain',
          body: 'hereisthetext'
        )
      end
      it { is_expected.to match(/hereisthetext/) }
    end

    context 'xls' do
      let(:attachment) do
        FoiAttachment.new(
          content_type: 'application/vnd.ms-excel',
          body: load_file_fixture('interesting.xls')
        )
      end

      it 'includes the first sheet name' do
        is_expected.to match(/Sheet1/)
      end

      it 'includes the first sheet contents' do
        is_expected.to match(/foo/)
      end

      it 'includes subsequent sheet names' do
        is_expected.to match(/Sheet2/)
      end

      it 'includes subsequent sheet contents' do
        is_expected.to match(/baz/)
      end
    end

    context 'xlsx' do
      let(:attachment) do
        FoiAttachment.new(
          content_type: 'application/vnd.openxmlformats-officedocument.' \
            'spreadsheetml.sheet',
          body: body
        )
      end
      let(:body) { load_file_fixture('interesting.xlsx') }

      it 'includes the first sheet name' do
        is_expected.to match(/Sheet1/)
      end

      it 'includes the first sheet contents' do
        is_expected.to match(/foo/)
      end

      it 'includes subsequent sheet names' do
        is_expected.to match(/Sheet2/)
      end

      it 'includes subsequent sheet contents' do
        is_expected.to match(/baz/)
      end

      context 'with a sparsely populated spreadsheet' do
        let(:body) { load_file_fixture('sparse.xlsx') }

        it 'extracts the substantive contents' do
          is_expected.to match(/cat/)
        end

        it 'squeezes repetitive commas' do
          is_expected.not_to match(/,,/)
        end
      end
    end

    context 'csv' do
      let(:attachment) do
        FoiAttachment.new(
          content_type: 'text/csv',
          body: load_file_fixture('interesting.csv')
        )
      end
      it { is_expected.to match(/foo/) }
      it { is_expected.to match(/maçã/) }
    end

    context 'zip' do
      let(:attachment) do
        FoiAttachment.new(
          content_type: 'application/zip',
          body: load_file_fixture('example.zip')
        )
      end

      it { is_expected.to match(/Contravention/) }

      context 'when the expansion of the zip raises an error' do
        before do
          mock_entry = double('Zip::File entry', file?: true)

          allow(mock_entry).
            to receive(:get_input_stream).
            and_raise('invalid distance too far back')

          mock_entries = [mock_entry]
          allow(mock_entries).to receive(:close)

          allow(Zip::File).to receive(:open).and_return(mock_entries)
        end

        it { is_expected.to be_empty }
      end
    end

    # Unhandled and unlikely to be
    # --------------------------------------------------------------------------

    context 'jpeg' do
      let(:attachment) do
        FoiAttachment.new(
          content_type: 'image/jpeg',
          body: 'someimage'
        )
      end
      it { is_expected.to be_empty }
    end
  end
end
