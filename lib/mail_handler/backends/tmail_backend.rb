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

            # Return a copy of the file name for the mail part
            def get_part_file_name(mail_part)
                part_file_name = TMail::Mail.get_part_file_name(mail_part)
                if part_file_name.nil?
                    return nil
                end
                part_file_name = part_file_name.dup
                return part_file_name
            end

            def get_part_body(mail_part)
                mail_part.body
            end

            def address_from_name_and_email(name, email)
                if !MySociety::Validate.is_valid_email(email)
                    raise "invalid email " + email + " passed to address_from_name_and_email"
                end
                if name.nil?
                    return TMail::Address.parse(email).to_s
                end
                # Botch an always quoted RFC address, then parse it
                name = name.gsub(/(["\\])/, "\\\\\\1")
                TMail::Address.parse('"' + name + '" <' + email + '>').to_s
            end

            def address_from_string(string)
                TMail::Address.parse(string).address
            end

        end
    end
end