require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe AttachmentToHTML::Adapters::RTF do

    let(:attachment) { FactoryGirl.build(:rtf_attachment) }
    let(:rtf_adapter) { AttachmentToHTML::Adapters::RTF.new(attachment) }

    describe :wrapper do

        it 'defaults to wrapper' do
           rtf_adapter.wrapper.should == 'wrapper'
        end

        it 'accepts a wrapper option' do
            rtf_adapter = AttachmentToHTML::Adapters::RTF.new(attachment, :wrapper => 'wrap')
            rtf_adapter.wrapper.should == 'wrap'
        end
 
    end

    describe :tmpdir do

        it 'defaults to the rails tmp directory' do
           rtf_adapter.tmpdir.should == Rails.root.join('tmp') 
        end

        it 'allows a tmpdir to be specified to store the converted document' do
            rtf_adapter = AttachmentToHTML::Adapters::RTF.new(attachment, :tmpdir => '/tmp')
            rtf_adapter.tmpdir.should == '/tmp'
        end
  
    end

    describe :to_html do

        it 'contains the attachment filename in the title tag' do
            parsed = Nokogiri::HTML.parse(rtf_adapter.to_html)
            parsed.css('head title').inner_html.should == attachment.display_filename
        end

        it 'contains the wrapper div in the body tag' do
            rtf_adapter = AttachmentToHTML::Adapters::RTF.new(attachment, :wrapper => 'wrap')
            parsed = Nokogiri::HTML.parse(rtf_adapter.to_html)
            parsed.css('body div').first.attributes['id'].value.should == 'wrap'
        end

        it 'contains the attachment body in the wrapper div' do
            rtf_adapter = AttachmentToHTML::Adapters::RTF.new(attachment, :wrapper => 'wrap')
            parsed = Nokogiri::HTML.parse(rtf_adapter.to_html)
            parsed.css('div#wrap').inner_text.should include('thisisthebody')
        end

        it 'operates in the context of the supplied tmpdir' do
            rtf_adapter = AttachmentToHTML::Adapters::RTF.new(attachment, :tmpdir => '/tmp')
            Dir.should_receive(:chdir).with('/tmp').and_call_original
            rtf_adapter.to_html
        end

    end

    describe :success? do

        it 'is successful if the body has content excluding the tags' do
            rtf_adapter.to_html
            rtf_adapter.success?.should be_true
        end

        it 'is successful if the body contains images' do
            mocked_return = %Q(<!DOCTYPE html><html><head></head><body><img src="logo.png" /></body></html>)
            rtf_adapter = AttachmentToHTML::Adapters::RTF.new(attachment)
            rtf_adapter.stub(:to_html).and_return(mocked_return)
            rtf_adapter.success?.should be_true
        end

        it 'is not successful if the body has no content other than tags' do
            attachment = FactoryGirl.build(:body_text, :body => '')
            rtf_adapter = AttachmentToHTML::Adapters::RTF.new(attachment)
            rtf_adapter.to_html
            rtf_adapter.success?.should be_false
        end

    end

end
