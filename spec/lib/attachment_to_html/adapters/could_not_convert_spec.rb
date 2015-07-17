# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe AttachmentToHTML::Adapters::CouldNotConvert do

  let(:attachment) { FactoryGirl.build(:pdf_attachment) }
  let(:adapter) do
    AttachmentToHTML::Adapters::CouldNotConvert.new(attachment)
  end

  describe :title do

    it 'uses the attachment filename for the title' do
      adapter.title.should == attachment.display_filename
    end

  end

  describe :body do

    it 'contains a message asking the user to download the file directly' do
      expected = "<p>Sorry, we were unable to convert this file to HTML. " \
        "Please use the download link at the top right.</p>"
      adapter.body.should == expected
    end

  end

  describe :success? do

    it 'is always true' do
      adapter.success?.should be_true
    end

  end

end
