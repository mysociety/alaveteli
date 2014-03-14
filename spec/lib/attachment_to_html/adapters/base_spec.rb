require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe AttachmentToHTML::Adapters::Text do

    describe '.template' do

        it 'reads the base template' do
            template = <<-END.gsub(/^ {16}/, '')
                <!DOCTYPE html>
                <html>
                  <head>
                    <title><%= title %></title>
                  </head>
                  <body>
                    <div id="<%= wrapper %>"><%= body %></div>
                  </body>
                </html>
            END
            AttachmentToHTML::Adapters::Base.template.should == template
        end

    end

    before(:each) do
        args = { :title => 'Hello', :body => 'Hello, World' }
        @base_adapter = AttachmentToHTML::Adapters::Base.new(args)
    end

    describe :title do

        it 'raises a NotImplementedError' do
           lambda{ @base_adapter.title }.should raise_error(NotImplementedError) 
        end
 
    end    

    describe :body do

        it 'raises a NotImplementedError' do
           lambda{ @base_adapter.body }.should raise_error(NotImplementedError) 
        end
 
    end

    describe :to_html do

        # We can't actually test this until Base is inherited from and the
        # attribute accessors are defined
        it 'defines to_html' do
            @base_adapter.should respond_to(:to_html)
        end
     
    end

end