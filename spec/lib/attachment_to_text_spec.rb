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
    end

    context 'pdf' do
      let(:attachment) { FactoryBot.create(:pdf_attachment) }
      it { is_expected.to match(/thisisthebody/) }
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
    end

    context 'csv' do
      let(:attachment) { FactoryBot.create(:csv_attachment) }
      it { is_expected.to match(/foo/) }
      it { is_expected.to match(/maçã/) }
    end

    # TODO: Add factory
    context 'zip' do
    end

    # Unhandled and unlikely to be
    # --------------------------------------------------------------------------

    context 'jpeg' do
      let(:attachment) { FactoryBot.create(:jpeg_attachment) }
      it { is_expected.to be_empty }
    end
  end
end
