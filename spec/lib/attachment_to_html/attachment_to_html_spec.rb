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

        it 'raises an exception if a suitable converter does not exist' do
            attachment = FactoryGirl.build(:foi_attachment, :content_type => 'application/json')
            lambda{ to_html(attachment, {}) }.should raise_error('No adapter for application/json attachments')
        end

    end

end
