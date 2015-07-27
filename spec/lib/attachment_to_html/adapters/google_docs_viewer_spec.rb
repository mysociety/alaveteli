# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe AttachmentToHTML::Adapters::GoogleDocsViewer do

  let(:attachment) { FactoryGirl.build(:pdf_attachment) }
  let(:adapter) do
    AttachmentToHTML::Adapters::GoogleDocsViewer.new(attachment, :attachment_url => 'http://example.com/test.pdf')
  end

  describe :title do

    it 'uses the attachment filename for the title' do
      adapter.title.should == attachment.display_filename
    end

  end

  describe :body do

    it 'contains the google docs viewer iframe' do
      expected = %Q(<iframe src="http://docs.google.com/viewer?url=http://example.com/test.pdf&amp;embedded=true" width="100%" height="100%" style="border: none;"></iframe>)
      adapter.body.should == expected
    end

    describe 'uses the confugured alaveteli protocol' do

      it 'https if force_ssl is on' do
        AlaveteliConfiguration.stub(:force_ssl).and_return(true)
        adapter.body.should include('https://docs.google.com')
      end

      it 'http if force_ssl is off' do
        AlaveteliConfiguration.stub(:force_ssl).and_return(false)
        adapter.body.should include('http://docs.google.com')
      end

    end

  end

  describe :success? do

    it 'is always true' do
      adapter.success?.should be_true
    end

  end

end
