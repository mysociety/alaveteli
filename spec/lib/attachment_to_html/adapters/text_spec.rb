require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe AttachmentToHTML::Adapters::Text do

    let(:attachment) { FactoryGirl.build(:body_text) }
    let(:text_adapter) { AttachmentToHTML::Adapters::Text.new(attachment) }

    describe :wrapper do

        it 'defaults to wrapper' do
           text_adapter.wrapper.should == 'wrapper'
        end

        it 'accepts a wrapper option' do
            text_adapter = AttachmentToHTML::Adapters::Text.new(attachment, :wrapper => 'wrap')
            text_adapter.wrapper.should == 'wrap'
        end
 
    end

    describe :to_html do

        it 'looks roughly like a html document' do
            htmlish = /<!DOCTYPE html>.*<html.*>.*<head>.*<title>.*<\/title>.*<\/head>.*<body.*>.*<\/body>.*<\/html>/im
            text_adapter.to_html.should match(htmlish)
        end

        it 'contains the attachment filename in the title tag' do
            parsed = Nokogiri::HTML.parse(text_adapter.to_html)
            parsed.css('title').inner_html.should == attachment.display_filename
        end

        it 'contains the wrapper div in the body tag' do
            text_adapter = AttachmentToHTML::Adapters::Text.new(attachment, :wrapper => 'wrap')
            parsed = Nokogiri::HTML.parse(text_adapter.to_html)
            parsed.css('body').children.first.attributes['id'].value.should == 'wrap'
        end

        it 'contains the attachment body in the wrapper div' do
            text_adapter = AttachmentToHTML::Adapters::Text.new(attachment, :wrapper => 'wrap')
            parsed = Nokogiri::HTML.parse(text_adapter.to_html)
            parsed.css('div#wrap').inner_html.should == attachment.body
        end
 
        it 'strips the body of trailing whitespace' do
            attachment = FactoryGirl.build(:body_text, :body => ' Hello ')
            text_adapter = AttachmentToHTML::Adapters::Text.new(attachment)
            parsed = Nokogiri::HTML.parse(text_adapter.to_html)
            parsed.css('div#wrapper').inner_html.should == 'Hello'
        end

        it 'escapes special characters' do
            attachment = FactoryGirl.build(:body_text, :body => 'Usage: foo "bar" >baz<')
            text_adapter = AttachmentToHTML::Adapters::Text.new(attachment)
            parsed = Nokogiri::HTML.parse(text_adapter.to_html)
            expected = %Q(Usage: foo &quot;bar&quot; &gt;baz&lt;)
            parsed.css('div#wrapper').inner_html.should == expected
        end

        it 'creates hyperlinks for text that looks like a url' do
            attachment = FactoryGirl.build(:body_text, :body => 'http://www.whatdotheyknow.com')
            text_adapter = AttachmentToHTML::Adapters::Text.new(attachment)
            parsed = Nokogiri::HTML.parse(text_adapter.to_html)
            parsed.css('div#wrapper a').first.text.should == 'http://www.whatdotheyknow.com'
            parsed.css('div#wrapper a').first['href'].should == 'http://www.whatdotheyknow.com'
        end

        it 'substitutes newlines for br tags' do
            attachment = FactoryGirl.build(:body_text, :body => "A\nNewline")
            text_adapter = AttachmentToHTML::Adapters::Text.new(attachment)
            parsed = Nokogiri::HTML.parse(text_adapter.to_html)
            expected = %Q(A<br>Newline)
            parsed.css('div#wrapper').inner_html.should == expected
        end

    end

    describe :success? do

        it 'is successful if the body has content excluding the tags' do
            text_adapter.to_html
            text_adapter.success?.should be_true
        end

        it 'is successful if the body contains images' do
            mocked_return = %Q(<!DOCTYPE html><html><head></head><body><img src="logo.png" /></body></html>)
            text_adapter = AttachmentToHTML::Adapters::Text.new(attachment)
            text_adapter.stub(:to_html).and_return(mocked_return)
            text_adapter.success?.should be_true
        end

        it 'is not successful if the body has no content other than tags' do
            attachment = FactoryGirl.build(:body_text, :body => '')
            text_adapter = AttachmentToHTML::Adapters::Text.new(attachment)
            text_adapter.to_html
            text_adapter.success?.should be_false
        end

    end

end
