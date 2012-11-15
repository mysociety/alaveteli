require 'mail'

module MailHandler
    module Backends
        module MailBackend

            def backend()
                'Mail'
            end

            # Note that the decode flag is not yet used
            def mail_from_raw_email(data, decode=true)
                Mail.new(data)
            end

             # Extracts all attachments from the given TNEF file as a Mail object
            def mail_from_tnef(content)
                main = Mail.new
                tnef_attachments(content).each do |attachment|
                    main.add_file(attachment)
                end
                main.ready_to_send!
                main
            end
        end
    end
end