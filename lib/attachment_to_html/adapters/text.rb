module AttachmentToHTML
    module Adapters
        class Text < Base

           def title
               @title
           end

           def body
               text = @body.strip
               text = CGI.escapeHTML(text)
               text = MySociety::Format.make_clickable(text)
               html = text.gsub(/\n/, '<br>')         
           end

        end
    end
end
