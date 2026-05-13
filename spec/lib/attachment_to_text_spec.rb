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

    # FIXME: Does not extract text from example file
    context 'ppt' do
      let(:attachment) { FactoryBot.create(:ppt_attachment) }
      xit { is_expected.to match(/interesting/) }
    end

    context 'rtf' do
      let(:attachment) { FactoryBot.create(:rtf_attachment) }
      it { is_expected.to match(/thisisthebody/) }
    end

    context 'txt' do
      let(:attachment) { FactoryBot.create(:body_text) }
      it { is_expected.to match(/hereisthetext/) }
    end

    # FIXME: Does not extract text from example file
    context 'xls' do
      let(:attachment) { FactoryBot.create(:xls_attachment) }
      xit { is_expected.to match(/foo/) }
    end

    # TODO: Add factory
    context 'zip' do
    end

    # Unhandled but desirable
    # --------------------------------------------------------------------------

    context 'csv' do
      let(:attachment) { FactoryBot.create(:csv_attachment) }
      it { is_expected.to be_empty }
    end

    context 'xlsx' do
      let(:attachment) { FactoryBot.create(:xlsx_attachment) }
      xit { is_expected.to match(/foo/) }
    end

    context 'pptx' do
      let(:attachment) { FactoryBot.create(:pptx_attachment) }
      xit { is_expected.to match(/interesting/) }
    end

    # Unhandled and unlikely to be
    # --------------------------------------------------------------------------

    context 'jpeg' do
      let(:attachment) { FactoryBot.create(:jpeg_attachment) }
      it { is_expected.to be_empty }
    end
  end
end
