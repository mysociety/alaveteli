# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe AttachmentToHTML::Adapters::Text do

  let(:attachment) { FactoryGirl.build(:body_text) }
  let(:adapter) { AttachmentToHTML::Adapters::Text.new(attachment) }

  describe :title do

    it 'uses the attachment filename for the title' do
      expect(adapter.title).to eq(attachment.display_filename)
    end

  end

  describe :body do

    it 'extracts the body from the document' do
      expect(adapter.body).to eq(attachment.body)
    end

    it 'strips the body of trailing whitespace' do
      attachment = FactoryGirl.build(:body_text, :body => ' Hello ')
      adapter = AttachmentToHTML::Adapters::Text.new(attachment)
      expect(adapter.body).to eq('Hello')
    end

    it 'escapes special characters' do
      attachment = FactoryGirl.build(:body_text, :body => 'Usage: foo "bar" >baz<')
      adapter = AttachmentToHTML::Adapters::Text.new(attachment)
      expected = %Q(Usage: foo &quot;bar&quot; &gt;baz&lt;)
      expect(adapter.body).to eq(expected)
    end

    it 'creates hyperlinks for text that looks like a url' do
      attachment = FactoryGirl.build(:body_text, :body => 'http://www.whatdotheyknow.com')
      adapter = AttachmentToHTML::Adapters::Text.new(attachment)
      expected = %Q(<a href='http://www.whatdotheyknow.com'>http://www.whatdotheyknow.com</a>)
      expect(adapter.body).to eq(expected)
    end

    it 'substitutes newlines for br tags' do
      attachment = FactoryGirl.build(:body_text, :body => "A\nNewline")
      adapter = AttachmentToHTML::Adapters::Text.new(attachment)
      expected = %Q(A<br>Newline)
      expect(adapter.body).to eq(expected)
    end

  end

  describe :success? do

    it 'is truthy if the body has content excluding the tags' do
      allow(adapter).to receive(:body).and_return('<p>some content</p>')
      expect(adapter.success?).to be_truthy
    end

    it 'is truthy if the body contains images' do
      allow(adapter).to receive(:body).and_return(%Q(<img src="logo.png" />))
      expect(adapter.success?).to be_truthy
    end

    it 'is falsey if the body has no content other than tags' do
      allow(adapter).to receive(:body).and_return('<p></p>')
      expect(adapter.success?).to be_falsey
    end

  end

end
