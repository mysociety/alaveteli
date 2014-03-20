require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AttachmentToHTML::HTML do

    let(:adapter) { OpenStruct.new(:to_html => '<p>hello</p>', :success? => true) }
    let(:html) { AttachmentToHTML::HTML.new(adapter) }

    describe :to_s do

        it 'returns the raw html' do
           html.to_s.should == '<p>hello</p>'
        end
 
    end

    describe :success? do

        it 'returns whether the conversion succeeded' do
           html.success?.should be_true 
        end
 
    end

end
