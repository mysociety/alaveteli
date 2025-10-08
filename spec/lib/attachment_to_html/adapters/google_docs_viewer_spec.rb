require 'spec_helper'

RSpec.describe AttachmentToHTML::Adapters::GoogleDocsViewer do
  describe '.viewable?' do
    subject { described_class.viewable?(content_type) }

    context 'when the content_type is supported' do
      let(:content_type) { 'application/pdf' }
      it { is_expected.to eq(true) }
    end

    context 'when the content_type is unsupported' do
      let(:content_type) { 'an/invalid/content-type' }
      it { is_expected.to eq(false) }
    end
  end

  let(:attachment) { FactoryBot.build(:pdf_attachment) }
  let(:adapter) do
    AttachmentToHTML::Adapters::GoogleDocsViewer.new(attachment, attachment_url: 'http://example.com/test.pdf')
  end

  describe :title do
    it 'uses the attachment filename for the title' do
      expect(adapter.title).to eq(attachment.display_filename)
    end
  end

  describe :body do
    it 'contains the google docs viewer iframe' do
      expected = %Q(<iframe src="https://docs.google.com/viewer?url=http://example.com/test.pdf&amp;embedded=true" width="100%" height="100%" style="border: none;"></iframe>)
      expect(adapter.body).to eq(expected)
    end
  end

  describe :success? do
    it 'is always true' do
      expect(adapter.success?).to be true
    end
  end

  describe :embed? do
    it 'returns true' do
      expect(adapter.embed?).to eq true
    end
  end
end
