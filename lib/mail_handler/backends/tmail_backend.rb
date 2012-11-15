# Monkeypatch! Adding some extra members to store extra info in.
module TMail
    class Mail
        attr_accessor :url_part_number
        attr_accessor :rfc822_attachment # when a whole email message is attached as text
        attr_accessor :within_rfc822_attachment # for parts within a message attached as text (for getting subject mainly)
    end
end

module MailHandler
    module Backends
        module TmailBackend

            def backend()
                'TMail'
            end

        end
    end
end