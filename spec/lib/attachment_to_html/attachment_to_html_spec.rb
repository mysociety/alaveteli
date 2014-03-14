require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AttachmentToHTML do

    describe :to_html do

        it 'sends the text to the specified adapter for conversion' do
            text = 'Hello, World'
            AttachmentToHTML::Adapters::Text.should_receive(:new)
            AttachmentToHTML::to_html
        end
 
        it 'can accept body, title and wrapper options' do
            opts = { :body => 'Hello, World',
                     :title => 'Hello',
                     :wrapper => 'wrap' }
            AttachmentToHTML::Adapters::Text.should_receive(:to_html).with(opts)
            AttachmentToHTML::to_html(:text, opts)
        end
 
        it 'raises an exception if the base adapter is supplied' do
            lambda{ AttachmentToHTML::to_html(:base, :body => 'Hello, World') }.should raise_error(NameError)
        end
 
        it 'raises an exception if an unknown adapter is supplied' do
            lambda{ AttachmentToHTML::to_html(:unknown, :body => 'Hello, World') }.should raise_error(NameError)
        end
 
    end

end
