require 'forwardable'
module AttachmentToHTML
    class HTML
        extend Forwardable

        def_delegator :@adapter, :to_html, :to_s
        def_delegator :@adapter, :success?

        def initialize(adapter)
            @adapter = adapter
        end

    end
end
