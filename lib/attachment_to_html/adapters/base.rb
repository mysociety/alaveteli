module AttachmentToHTML
    module Adapters
        class Base < ERB

            def self.template
                file = File.expand_path(File.dirname(__FILE__) + '/templates/base.html.erb')
                File.read(file)
            end

            attr_reader :wrapper

            def initialize(args)
                @title = args[:title]
                @body = args[:body]
                @wrapper = args.fetch(:wrapper, 'wrapper')
                @template = args.fetch(:template, self.class.template)        
                super(@template)
            end

           def to_html
               # wrapper_id = "wrapper"
               #            
               # text = body.strip
               # text = CGI.escapeHTML(text)
               # text = MySociety::Format.make_clickable(text)
               # html = text.gsub(/\n/, '<br>')

               result
           end

           def title
               raise NotImplementedError
           end

           def body
               raise NotImplementedError
           end

           private

           def result
             super(binding)
           end

        end
    end
end
