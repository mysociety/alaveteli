# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AttachmentToHTML do
  include AttachmentToHTML

  let(:attachment) { FactoryGirl.build(:body_text) }

  describe :to_html do

    it 'sends the attachment to the correct adapter for conversion' do
      AttachmentToHTML::Adapters::Text.should_receive(:new).with(attachment, {}).and_call_original
      to_html(attachment)
    end

    it 'renders the attachment as html' do
      adapter = AttachmentToHTML::Adapters::Text.new(attachment)
      expected = AttachmentToHTML::View.new(adapter).render
      to_html(attachment).should == expected
    end

    it 'passes content injections options when rendering the result' do
      html = to_html(attachment, :content_for => { :body_prefix => '<p>prefix</p>' })
      html.should include('<p>prefix</p>')
    end

    it 'accepts a hash of options to pass to the adapter' do
      options = { :wrapper => 'wrap' }
      AttachmentToHTML::Adapters::Text.should_receive(:new).with(attachment, options).and_call_original
      to_html(attachment, options)
    end

    it 'converts an attachment that has an adapter, fails to convert, but has a google viewer' do
      attachment = FactoryGirl.build(:pdf_attachment)
      AttachmentToHTML::Adapters::PDF.any_instance.stub(:success?).and_return(false)
      AttachmentToHTML::Adapters::PDF.should_receive(:new).with(attachment, {}).and_call_original
      AttachmentToHTML::Adapters::GoogleDocsViewer.should_receive(:new).with(attachment, {}).and_call_original
      to_html(attachment)
    end

    it 'converts an attachment that doesnt have an adapter, but has a google viewer' do
      attachment = FactoryGirl.build(:body_text, :content_type => 'application/vnd.ms-word')
      AttachmentToHTML::Adapters::GoogleDocsViewer.should_receive(:new).with(attachment, {}).and_call_original
      to_html(attachment)
    end

    it 'converts an attachment that has no adapter or google viewer' do
      attachment = FactoryGirl.build(:body_text, :content_type => 'application/json')
      AttachmentToHTML::Adapters::CouldNotConvert.should_receive(:new).with(attachment, {}).and_call_original
      to_html(attachment)
    end

    describe 'when wrapping the content' do

      it 'uses a the default wrapper' do
        attachment = FactoryGirl.build(:pdf_attachment)
        to_html(attachment).should include(%Q(<div id="wrapper">))
      end

      it 'uses a custom wrapper for GoogleDocsViewer attachments' do
        attachment = FactoryGirl.build(:pdf_attachment)
        # TODO: Add a document that will always render in a
        # GoogleDocsViewer for testing
        AttachmentToHTML::Adapters::PDF.any_instance.stub(:success?).and_return(false)
        to_html(attachment).should include(%Q(<div id="wrapper_google_embed">))
      end

    end

  end

end
