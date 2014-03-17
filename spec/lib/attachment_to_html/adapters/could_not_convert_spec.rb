require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe AttachmentToHTML::Adapters::CouldNotConvert do

    let(:attachment) { FactoryGirl.build(:pdf_attachment) }
    let(:adapter) { AttachmentToHTML::Adapters::CouldNotConvert.new(attachment) }

    describe :wrapper do

        it 'defaults to wrapper' do
           adapter.wrapper.should == 'wrapper'
        end

        it 'accepts a wrapper option' do
            adapter = AttachmentToHTML::Adapters::CouldNotConvert.new(attachment, :wrapper => 'wrap')
            adapter.wrapper.should == 'wrap'
        end
 
    end

    describe :to_html do

        it 'should be a valid html document' do
            parsed = Nokogiri::HTML.parse(adapter.to_html) do |config|
               config.strict
            end
            parsed.errors.any?.should be_false
        end

        it 'contains the attachment filename in the title tag' do
            parsed = Nokogiri::HTML.parse(adapter.to_html) do |config|
               config.strict
            end
            parsed.css('title').inner_html.should == attachment.display_filename
        end

        it 'contains the wrapper div in the body tag' do
            adapter = AttachmentToHTML::Adapters::CouldNotConvert.new(attachment, :wrapper => 'wrap')
            parsed = Nokogiri::HTML.parse(adapter.to_html) do |config|
               config.strict
            end
            parsed.css('body div').first.attributes['id'].value.should == 'wrap'
        end

        it 'should contain text about the conversion failure' do
            adapter = AttachmentToHTML::Adapters::CouldNotConvert.new(attachment, :wrapper => 'wrap')
            parsed = Nokogiri::HTML.parse(adapter.to_html) do |config|
                config.strict
            end

            expected = "<p>Sorry, we were unable to convert this file to HTML. " \
                       "Please use the download link at the top right.</p>"

            parsed.css('div#wrap div#view-html-content').inner_html.should == expected
        end

    end

    describe :success? do

        it 'is always true' do
            adapter.success?.should be_true
        end

    end

end
