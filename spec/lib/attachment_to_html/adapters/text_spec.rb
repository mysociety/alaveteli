# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe AttachmentToHTML::Adapters::Text do

  let(:attachment) { FactoryGirl.build(:body_text) }
  let(:adapter) { AttachmentToHTML::Adapters::Text.new(attachment) }

  describe :title do

    it 'uses the attachment filename for the title' do
      adapter.title.should == attachment.display_filename
    end

  end

  describe :body do

    it 'extracts the body from the document' do
      adapter.body.should == attachment.body
    end

    it 'strips the body of trailing whitespace' do
      attachment = FactoryGirl.build(:body_text, :body => ' Hello ')
      adapter = AttachmentToHTML::Adapters::Text.new(attachment)
      adapter.body.should == 'Hello'
    end

    it 'escapes special characters' do
      attachment = FactoryGirl.build(:body_text, :body => 'Usage: foo "bar" >baz<')
      adapter = AttachmentToHTML::Adapters::Text.new(attachment)
      expected = %Q(Usage: foo &quot;bar&quot; &gt;baz&lt;)
      adapter.body.should == expected
    end

    it 'creates hyperlinks for text that looks like a url' do
      attachment = FactoryGirl.build(:body_text, :body => 'http://www.whatdotheyknow.com')
      adapter = AttachmentToHTML::Adapters::Text.new(attachment)
      expected = %Q(<a href='http://www.whatdotheyknow.com'>http://www.whatdotheyknow.com</a>)
      adapter.body.should == expected
    end

    it 'substitutes newlines for br tags' do
      attachment = FactoryGirl.build(:body_text, :body => "A\nNewline")
      adapter = AttachmentToHTML::Adapters::Text.new(attachment)
      expected = %Q(A<br>Newline)
      adapter.body.should == expected
    end

  end

  describe :success? do

    it 'is successful if the body has content excluding the tags' do
      adapter.stub(:body).and_return('<p>some content</p>')
      adapter.success?.should be_true
    end

    it 'is successful if the body contains images' do
      adapter.stub(:body).and_return(%Q(<img src="logo.png" />))
      adapter.success?.should be_true
    end

    it 'is not successful if the body has no content other than tags' do
      adapter.stub(:body).and_return('<p></p>')
      adapter.success?.should be_false
    end

  end

end
