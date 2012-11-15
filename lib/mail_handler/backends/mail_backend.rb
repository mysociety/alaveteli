require 'mail'

module MailHandler
    module Backends
        module MailBackend

            def backend()
                'Mail'
            end

            def mail_from_raw_email(data)
                Mail.new(data)
            end

        end
    end
end