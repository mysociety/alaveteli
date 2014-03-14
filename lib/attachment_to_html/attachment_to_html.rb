Dir[File.dirname(__FILE__) + '/adapters/*.rb'].each do |file|
  require file
end

module AttachmentToHTML
    extend self

    def to_html(adapter_name, opts = {})
        case adapter_name
        when Symbol, String
            raise "Missing adapter #{ adapter_name }" if adapter_name.to_s == 'base'
            @adapter = AttachmentToHTML::Adapters.const_get("#{adapter_name.to_s.capitalize}").new(opts)
        else
            raise "Missing adapter #{ adapter_name }"
        end

        @adapter.to_html
    end
    
end
