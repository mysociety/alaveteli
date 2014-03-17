require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe AttachmentToHTML::Adapters::GoogleDocsViewer do

    let(:attachment) { FactoryGirl.build(:pdf_attachment) }
    let(:google_adapter) do
        AttachmentToHTML::Adapters::GoogleDocsViewer.new(attachment, :attachment_url => 'http://example.com/test.pdf')
    end

    describe :wrapper do

        it 'defaults to wrapper_google_embed' do
           google_adapter.wrapper.should == 'wrapper_google_embed'
        end

        it 'accepts a wrapper option' do
            google_adapter = AttachmentToHTML::Adapters::GoogleDocsViewer.new(attachment, :wrapper => 'wrap')
            google_adapter.wrapper.should == 'wrap'
        end
 
    end

    describe :to_html do

        it 'should be a valid html document' do
            parsed = Nokogiri::HTML.parse(google_adapter.to_html) do |config|
               config.strict
            end
            parsed.errors.any?.should be_false
        end

        it 'contains the attachment filename in the title tag' do
            parsed = Nokogiri::HTML.parse(google_adapter.to_html) do |config|
               config.strict
            end
            parsed.css('title').inner_html.should == attachment.display_filename
        end

        it 'contains the wrapper div in the body tag' do
            google_adapter = AttachmentToHTML::Adapters::GoogleDocsViewer.new(attachment, :wrapper => 'wrap')
            parsed = Nokogiri::HTML.parse(google_adapter.to_html) do |config|
               config.strict
            end
            parsed.css('body div').first.attributes['id'].value.should == 'wrap'
        end

        it 'contains the google docs viewer url in the wrapper div' do
            options = { :wrapper => 'wrap', :attachment_url => 'http://example.com/test.pdf' }
            google_adapter = AttachmentToHTML::Adapters::GoogleDocsViewer.new(attachment, options)
            parsed = Nokogiri::HTML.parse(google_adapter.to_html) do |config|
               config.strict
            end
            expected = %Q(<iframe src="http://docs.google.com/viewer?url=http://example.com/test.pdf&amp;embedded=true" width="100%" height="100%" style="border: none;"></iframe>)
            parsed.css('div#wrap div#view-html-content').inner_html.should include(expected)
        end

        describe 'uses the confugured alaveteli protocol' do

            it 'https if force_ssl is on' do
                AlaveteliConfiguration.stub(:force_ssl).and_return(true)
                google_adapter.to_html.should include('https://docs.google.com')
            end

            it 'http if force_ssl is off' do
                AlaveteliConfiguration.stub(:force_ssl).and_return(false)
                google_adapter.to_html.should include('http://docs.google.com')
            end

        end

    end

    describe :success? do

        it 'is always true' do
            google_adapter.success?.should be_true
        end

    end

end
