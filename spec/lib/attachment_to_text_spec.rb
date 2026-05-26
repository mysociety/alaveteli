require 'spec_helper'

RSpec.describe AttachmentToText do
  describe '#to_text' do
    subject { described_class.new(attachment).to_text }

    # Currently handled
    # --------------------------------------------------------------------------

    context 'doc' do
      let(:attachment) { FactoryBot.create(:doc_attachment) }
      it { is_expected.to match(/lorem/) }
    end

    context 'docx' do
      let(:attachment) { FactoryBot.create(:docx_attachment) }
      it { is_expected.to match(/lorem/) }
    end

    context 'html' do
      let(:attachment) { FactoryBot.create(:html_attachment) }

      it { is_expected.to match(/dull/) }

      context 'with UTF-8 characters' do
        let(:attachment) do
          FactoryBot.create(:html_attachment, body: '<html><b>foo</b> është')
        end

        it 'retains the UTF-8 characters in the extracted text' do
          is_expected.to match(/është/)
        end
      end
    end

    context 'pdf' do
      let(:attachment) { FactoryBot.create(:pdf_attachment) }
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
      let(:attachment) { FactoryBot.create(:ppt_attachment) }

      it 'includes contents from the first slide' do
        is_expected.to match(/Interesting/)
      end

      it 'includes contents from subsequent slides' do
        is_expected.to match(/Lorem/)
      end
    end

    context 'pptx' do
      let(:attachment) { FactoryBot.create(:pptx_attachment) }

      it 'includes contents from the first slide' do
        is_expected.to match(/Interesting/)
      end

      it 'includes contents from subsequent slides' do
        is_expected.to match(/Lorem/)
      end
    end

    context 'rtf' do
      let(:attachment) { FactoryBot.create(:rtf_attachment) }
      it { is_expected.to match(/thisisthebody/) }
    end

    context 'txt' do
      let(:attachment) { FactoryBot.create(:body_text) }
      it { is_expected.to match(/hereisthetext/) }
    end

    context 'xls' do
      let(:attachment) { FactoryBot.create(:xls_attachment) }

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
      let(:attachment) { FactoryBot.create(:xlsx_attachment) }

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
        let(:attachment) do
          FactoryBot.create(
            :xlsx_attachment,
            body: load_file_fixture('sparse.xlsx')
          )
        end

        it 'extracts the substantive contents' do
          is_expected.to match(/cat/)
        end

        it 'squeezes repetitive commas' do
          is_expected.not_to match(/,,/)
        end
      end
    end

    context 'csv' do
      let(:attachment) { FactoryBot.create(:csv_attachment) }
      it { is_expected.to match(/foo/) }
      it { is_expected.to match(/maçã/) }
    end

    context 'zip' do
      let(:attachment) { FactoryBot.create(:zip_attachment) }

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
      let(:attachment) { FactoryBot.create(:jpeg_attachment) }
      it { is_expected.to be_empty }
    end
  end
end
