require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe AttachmentToHTML::Adapters::Text do

    describe 'a new instance' do

        it 'has a body attribute' do
            AttachmentToHTML::Adapters::Text.new(:body => 'Hello, World').body.should == 'Hello, World'
        end

        it 'has a title attribute' do
            AttachmentToHTML::Adapters::Text.new(:title => 'Hello, World').title.should == 'Hello, World'
        end

        it 'has a default wrapper attribute' do
            AttachmentToHTML::Adapters::Text.new({}).wrapper.should == 'wrapper'
        end

        it 'may have a custom wrapper attribute' do
            AttachmentToHTML::Adapters::Text.new(:wrapper => 'main').wrapper.should == 'main'
        end

    end

    describe :to_html do

        before(:each) do
            args = { :title => 'Hello', :body => 'Hello, World' }
            @text_adapter = AttachmentToHTML::Adapters::Text.new(args)
        end

        it 'sends the text to the specified adapter for conversion' do
            text = 'Hello, World'
            @text_adapter.to_html(text).should == '<p>Hello, World</p>'
        end
     
    end

end
