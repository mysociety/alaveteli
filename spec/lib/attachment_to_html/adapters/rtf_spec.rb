# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe AttachmentToHTML::Adapters::RTF do

  let(:attachment) { FactoryGirl.build(:rtf_attachment) }
  let(:adapter) { AttachmentToHTML::Adapters::RTF.new(attachment) }

  describe :tmpdir do

    it 'defaults to the rails tmp directory' do
      expect(adapter.tmpdir).to eq(Rails.root.join('tmp'))
    end

    it 'allows a tmpdir to be specified to store the converted document' do
      adapter = AttachmentToHTML::Adapters::RTF.new(attachment, :tmpdir => '/tmp')
      expect(adapter.tmpdir).to eq('/tmp')
    end

  end

  describe :title do

    it 'uses the attachment filename for the title' do
      expect(adapter.title).to eq(attachment.display_filename)
    end

  end

  describe :body do

    it 'extracts the body from the document' do
      expect(adapter.body).to include('thisisthebody')
    end

    it 'operates in the context of the supplied tmpdir' do
      adapter = AttachmentToHTML::Adapters::RTF.new(attachment, :tmpdir => '/tmp')
      expect(Dir).to receive(:chdir).with('/tmp').and_call_original
      adapter.body
    end

    it 'does not result in incorrect conversion when unrtf returns an invalid doctype' do
      # Doctype public identifier is unquoted
      # Valid doctype would be:
      # <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
      # See bug report http://savannah.gnu.org/bugs/?42015
      invalid = <<-DOC
      <!DOCTYPE html PUBLIC -//W3C//DTD HTML 4.01 Transitional//EN>
      <html>
      <head>
      <meta http-equiv="content-type" content="text/html; charset=utf-8">
      <!-- Translation from RTF performed by UnRTF, version 0.21.5 -->
      <!--font table contains 0 fonts total-->
      <!--invalid font number 0-->
      </head>
      <body><font size="3"><font color="#000000">thisisthebody</font></font></body>
      </html>
      DOC
      allow(AlaveteliExternalCommand).to receive(:run).and_return(invalid)

      expect(adapter.body).not_to include('//W3C//DTD HTML 4.01 Transitional//EN')
    end

    it 'converts empty files' do
      attachment = FactoryGirl.build(:rtf_attachment, :body => load_file_fixture('empty.rtf'))
      adapter = AttachmentToHTML::Adapters::RTF.new(attachment)
      expect(adapter.body).to eq('')
    end

    it 'doesnt fail if the external command returns nil' do
      allow(AlaveteliExternalCommand).to receive(:run).and_return(nil)
      expect(adapter.body).to eq('')
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
