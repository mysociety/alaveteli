module AttachmentToHTML
    class View < ERB

        def self.template
            @template || "#{ File.dirname(__FILE__) }/template.html.erb"
        end

        def self.template=(path)
            @template = path
        end

        attr_accessor :title, :body, :template, :wrapper

        def initialize(adapter, opts = {})
            self.title    = adapter.title
            self.body     = adapter.body
            self.template = opts.fetch(:template, self.class.template)
            self.wrapper  = opts.fetch(:wrapper, 'wrapper')
            super(File.read(template))
        end

        def render
            result(binding)
        end

    end
end
