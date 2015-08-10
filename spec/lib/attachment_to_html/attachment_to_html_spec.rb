# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AttachmentToHTML do
  include AttachmentToHTML

  let(:attachment) { FactoryGirl.build(:body_text) }

  describe '#to_html' do

    it 'sends the attachment to the correct adapter for conversion' do
      expect(AttachmentToHTML::Adapters::Text).to receive(:new).with(attachment, {}).and_call_original
      to_html(attachment)
    end

    it 'renders the attachment as html' do
      adapter = AttachmentToHTML::Adapters::Text.new(attachment)
      expected = AttachmentToHTML::View.new(adapter).render
      expect(to_html(attachment)).to eq(expected)
    end

    it 'passes content injections options when rendering the result' do
      html = to_html(attachment, :content_for => { :body_prefix => '<p>prefix</p>' })
      expect(html).to include('<p>prefix</p>')
    end

    it 'accepts a hash of options to pass to the adapter' do
      options = { :wrapper => 'wrap' }
      expect(AttachmentToHTML::Adapters::Text).to receive(:new).with(attachment, options).and_call_original
      to_html(attachment, options)
    end

    it 'converts an attachment that has an adapter, fails to convert, but has a google viewer' do
      attachment = FactoryGirl.build(:pdf_attachment)
      allow_any_instance_of(AttachmentToHTML::Adapters::PDF).to receive(:success?).and_return(false)
      expect(AttachmentToHTML::Adapters::PDF).to receive(:new).with(attachment, {}).and_call_original
      expect(AttachmentToHTML::Adapters::GoogleDocsViewer).to receive(:new).with(attachment, {}).and_call_original
      to_html(attachment)
    end

    it 'converts an attachment that doesnt have an adapter, but has a google viewer' do
      attachment = FactoryGirl.build(:body_text, :content_type => 'application/vnd.ms-word')
      expect(AttachmentToHTML::Adapters::GoogleDocsViewer).to receive(:new).with(attachment, {}).and_call_original
      to_html(attachment)
    end

    it 'converts an attachment that has no adapter or google viewer' do
      attachment = FactoryGirl.build(:body_text, :content_type => 'application/json')
      expect(AttachmentToHTML::Adapters::CouldNotConvert).to receive(:new).with(attachment, {}).and_call_original
      to_html(attachment)
    end

    describe 'when wrapping the content' do

      it 'uses a the default wrapper' do
        attachment = FactoryGirl.build(:pdf_attachment)
        expect(to_html(attachment)).to include(%Q(<div id="wrapper">))
      end

      it 'uses a custom wrapper for GoogleDocsViewer attachments' do
        attachment = FactoryGirl.build(:pdf_attachment)
        # TODO: Add a document that will always render in a
        # GoogleDocsViewer for testing
        allow_any_instance_of(AttachmentToHTML::Adapters::PDF).to receive(:success?).and_return(false)
        expect(to_html(attachment)).to include(%Q(<div id="wrapper_google_embed">))
      end

    end

  end

end
