module MailHandler
    module Backends
        module TmailBackend

            def backend()
                'TMail'
            end

            # Turn raw data into a structured TMail::Mail object
            # Documentation at http://i.loveruby.net/en/projects/tmail/doc/
            def mail_from_raw_email(data, decode=true)
                # Hack round bug in TMail's MIME decoding.
                # Report of TMail bug:
                # http://rubyforge.org/tracker/index.php?func=detail&aid=21810&group_id=4512&atid=17370
                copy_of_raw_data = data.gsub(/; boundary=\s+"/im,'; boundary="')
                mail = TMail::Mail.parse(copy_of_raw_data)
                mail.base64_decode if decode
                mail
            end

            # Extracts all attachments from the given TNEF file as a TMail::Mail object
            def mail_from_tnef(content)
                main = TMail::Mail.new
                main.set_content_type 'multipart', 'mixed', { 'boundary' => TMail.new_boundary }
                tnef_attachments(content).each do |attachment|
                    tmail_attachment = TMail::Mail.new
                    tmail_attachment['content-location'] = attachment[:filename]
                    tmail_attachment.body = attachment[:content]
                    main.parts << tmail_attachment
                end
                main
            end

        end
    end
end