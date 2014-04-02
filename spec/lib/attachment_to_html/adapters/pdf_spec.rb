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
