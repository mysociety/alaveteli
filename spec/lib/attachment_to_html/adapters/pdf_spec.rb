# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe AttachmentToHTML::Adapters::PDF do

  let(:attachment) { FactoryGirl.build(:pdf_attachment) }
  let(:adapter) { AttachmentToHTML::Adapters::PDF.new(attachment) }

  describe :tmpdir do

    it 'defaults to the rails tmp directory' do
      adapter.tmpdir.should == Rails.root.join('tmp')
    end

    it 'allows a tmpdir to be specified to store the converted document' do
      adapter = AttachmentToHTML::Adapters::PDF.new(attachment, :tmpdir => '/tmp')
      adapter.tmpdir.should == '/tmp'
    end

  end

  describe :title do

    it 'uses the attachment filename for the title' do
      adapter.title.should == attachment.display_filename
    end

    it 'returns the title encoded as UTF-8' do
      if RUBY_VERSION.to_f >= 1.9
        adapter.title.encoding.should == Encoding.find('UTF-8')
      end
    end


  end

  describe :body do

    it 'extracts the body from the document' do
      adapter.body.should include('thisisthebody')
    end

    it 'operates in the context of the supplied tmpdir' do
      adapter = AttachmentToHTML::Adapters::PDF.new(attachment, :tmpdir => '/tmp')
      Dir.should_receive(:chdir).with('/tmp').and_call_original
      adapter.body
    end

    it 'returns the body encoded as UTF-8' do
      if RUBY_VERSION.to_f >= 1.9
        adapter.body.encoding.should == Encoding.find('UTF-8')
      end
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

    it 'is not successful if convert returns nil' do
      adapter.stub(:convert).and_return(nil)
      adapter.success?.should be_false
    end

    it 'is not successful if the body contains more than 50 images' do
      # Sometimes pdftohtml extracts images incorrectly, resulting
      # in thousands of PNGs being created for one image. This creates
      # a huge request spike when the converted attachment is requested.
      #
      # See bug report https://bugs.freedesktop.org/show_bug.cgi?id=77932

      # Construct mocked HTML output with 51 images
      invalid = <<-DOC
      <!DOCTYPE html>
      <HTML xmlns="http://www.w3.org/1999/xhtml" lang="" xml:lang="">
      <HEAD>
      <TITLE>Microsoft Word - FOI 12-01605 Resp 1.doc</TITLE>
      <META http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
            <META name="generator" content="pdftohtml 0.36"/>
      <META name="author" content="8065"/>
            <META name="date" content="2012-09-24T15:37:06+00:00"/>
      </HEAD>
      <BODY bgcolor="#A0A0A0" vlink="blue" link="blue">
      <A name=1></a><IMG src="FOI 12 01605 Resp 1 PDF-1_1.png"/><br/>
      <IMG src="FOI 12 01605 Resp 1 PDF-1_2.png"/><br/>
      DOC

      (3..51).each { |i| invalid += %Q(<IMG src="FOI 12 01605 Resp 1 PDF-1_#{i}.png"/><br/>) }

      invalid += <<-DOC
      &#160;<br/>
      Some Content<br/>
      <hr>
      </BODY>
      </HTML>
      DOC
      AlaveteliExternalCommand.stub(:run).and_return(invalid)

      adapter.success?.should be_false
    end

  end

end
