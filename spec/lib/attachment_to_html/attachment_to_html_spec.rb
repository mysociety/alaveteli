require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AttachmentToHTML do
    include AttachmentToHTML

    let(:attachment) { FactoryGirl.build(:body_text) }

    describe :to_html do

        it 'sends the attachment to the correct adapter for conversion' do
            AttachmentToHTML::Adapters::Text.should_receive(:new).with(attachment, {}).and_call_original
            to_html(attachment)
        end

        it 'returns the results in a HTML class' do
            expected = AttachmentToHTML::Adapters::Text.new(attachment).to_html
            to_html(attachment).should be_instance_of(AttachmentToHTML::HTML)
        end
 
        it 'accepts a hash of options to pass to the adapter' do
            options = { :wrapper => 'wrap' }
            AttachmentToHTML::Adapters::Text.should_receive(:new).with(attachment, options).and_call_original
            to_html(attachment, options)
        end

        it 'converts an attachment that has an adapter, fails to convert, but has a google viewer' do
            attachment = FactoryGirl.build(:pdf_attachment)
            AttachmentToHTML::HTML.any_instance.stub(:success?).and_return(false)
            AttachmentToHTML::Adapters::PDF.should_receive(:new).with(attachment, {}).and_call_original
            AttachmentToHTML::Adapters::GoogleDocsViewer.should_receive(:new).with(attachment, {})
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

    end

end
