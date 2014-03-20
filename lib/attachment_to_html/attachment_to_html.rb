require 'html'

Dir[File.dirname(__FILE__) + '/adapters/*.rb'].each do |file|
    require file
end

module AttachmentToHTML
    extend self

    def to_html(attachment, opts = {})
        adapter = adapter_for(attachment.content_type).new(attachment, opts)
        HTML.new(adapter)
    end

    private

    def adapter_for(content_type)
        case content_type
        when 'text/plain' then Adapters::Text
        when 'application/pdf' then Adapters::PDF
        when 'application/rtf' then Adapters::RTF
        else
            raise "No adapter for #{ content_type } attachments"
        end
    end

end
