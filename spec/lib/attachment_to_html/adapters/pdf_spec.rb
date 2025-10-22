require 'spec_helper'

RSpec.describe AttachmentToHTML::Adapters::PDF do
  let(:attachment) { FactoryBot.create(:pdf_attachment) }
  let(:adapter) do
    AttachmentToHTML::Adapters::PDF.new(attachment, attachment_url: 'http://example.com/test.pdf')
  end

  describe :title do
    it 'uses the attachment filename for the title' do
      expect(adapter.title).to eq(attachment.display_filename)
    end
  end

  describe :body do
    it 'contains an iframe to the attachment URL' do
      expected = %Q(<iframe src="http://example.com/test.pdf" width="100%" height="100%" style="border: none;"></iframe>)
      expect(adapter.body).to eq(expected)
    end
  end

  describe :success? do
    it 'returns true' do
      expect(adapter.success?).to eq true
    end
  end

  describe :embed? do
    it 'returns true' do
      expect(adapter.embed?).to eq true
    end
  end
end
