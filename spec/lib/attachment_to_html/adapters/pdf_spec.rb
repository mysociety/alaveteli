require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe AttachmentToHTML::Adapters::PDF do

    let(:attachment) { FactoryGirl.build(:pdf_attachment) }
    let(:pdf_adapter) { AttachmentToHTML::Adapters::PDF.new(attachment) }

    describe :wrapper do

        it 'defaults to wrapper' do
           pdf_adapter.wrapper.should == 'wrapper'
        end

        it 'accepts a wrapper option' do
            pdf_adapter = AttachmentToHTML::Adapters::PDF.new(attachment, :wrapper => 'wrap')
            pdf_adapter.wrapper.should == 'wrap'
        end
 
    end

    describe :tmpdir do

        it 'defaults to the rails tmp directory' do
           pdf_adapter.tmpdir.should == Rails.root.join('tmp') 
        end

        it 'allows a tmpdir to be specified to store the converted document' do
            pdf_adapter = AttachmentToHTML::Adapters::PDF.new(attachment, :tmpdir => '/tmp')
            pdf_adapter.tmpdir.should == '/tmp'
        end
  
    end

    describe :to_html do

        it 'looks roughly like a html document' do
            htmlish = /<!DOCTYPE html>.*<html.*>.*<head>.*<title>.*<\/title>.*<\/head>.*<body.*>.*<\/body>.*<\/html>/im
            pdf_adapter.to_html.should match(htmlish)
        end

        it 'contains the attachment filename in the title tag' do
            parsed = Nokogiri::HTML.parse(pdf_adapter.to_html)
            parsed.css('title').inner_html.should == attachment.display_filename
        end

        it 'contains the wrapper div in the body tag' do
            pdf_adapter = AttachmentToHTML::Adapters::PDF.new(attachment, :wrapper => 'wrap')
            parsed = Nokogiri::HTML.parse(pdf_adapter.to_html)
            parsed.css('body div').first.attributes['id'].value.should == 'wrap'
        end

        it 'contains the attachment body in the wrapper div' do
            pdf_adapter = AttachmentToHTML::Adapters::PDF.new(attachment, :wrapper => 'wrap')
            parsed = Nokogiri::HTML.parse(pdf_adapter.to_html)
            parsed.css('div#wrap').inner_html.should include('thisisthebody')
        end

        it 'operates in the context of the supplied tmpdir' do
            pdf_adapter = AttachmentToHTML::Adapters::PDF.new(attachment, :tmpdir => '/tmp')
            Dir.should_receive(:chdir).with('/tmp').and_call_original
            pdf_adapter.to_html
        end

    end

    describe :success? do

        it 'is successful if the body has content excluding the tags' do
            pdf_adapter.to_html
            pdf_adapter.success?.should be_true
        end

        it 'is successful if the body contains images' do
            mocked_return = %Q(<!DOCTYPE html><html><head></head><body><img src="logo.png" /></body></html>)
            pdf_adapter = AttachmentToHTML::Adapters::PDF.new(attachment)
            pdf_adapter.stub(:to_html).and_return(mocked_return)
            pdf_adapter.success?.should be_true
        end

        it 'is not successful if the body has no content other than tags' do
            attachment = FactoryGirl.build(:body_text, :body => '')
            pdf_adapter = AttachmentToHTML::Adapters::PDF.new(attachment)
            pdf_adapter.to_html
            pdf_adapter.success?.should be_false
        end

    end

end
