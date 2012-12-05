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

            # Get the body of a mail part
            def get_part_body(mail_part)
                mail_part.body
            end

            # Return the first from address if any
            def get_from_address(mail)
                if mail.from_addrs.nil? || mail.from_addrs.size == 0
                    return nil
                end
                mail.from_addrs[0].spec
            end

            # Return the first from name if any
            def get_from_name(mail)
                mail.from_name_if_present
            end

            def get_all_addresses(mail)
                ((mail.to || []) +
                (mail.cc || []) +
                (mail.envelope_to || [])).uniq
            end

            def empty_return_path?(mail)
                return false if mail['return-path'].nil?
                return true if mail['return-path'].addr.to_s == '<>'
                return false
            end

            def get_auto_submitted(mail)
                mail['auto-submitted'] ? mail['auto-submitted'].body : nil
            end

            def get_content_type(part)
                part.content_type
            end

            def get_header_string(header, mail)
                mail.header_string(header)
            end

            # Number the attachments in depth first tree order, for use in URLs.
            # XXX This fills in part.rfc822_attachment and part.url_part_number within
            # all the parts of the email (see monkeypatches in lib/mail_handler/tmail_extensions and
            # lib/mail_handler/mail_extensions for how these attributes are added). ensure_parts_counted
            # must be called before using the attributes.
            def ensure_parts_counted(mail)
                mail.count_parts_count = 0
                _count_parts_recursive(mail, mail)
                # we carry on using these numeric ids for attachments uudecoded from within text parts
                mail.count_first_uudecode_count = mail.count_parts_count
            end
            def _count_parts_recursive(part, mail)
                if part.multipart?
                    part.parts.each do |p|
                        _count_parts_recursive(p, mail)
                    end
                else
                    part_filename = MailHandler.get_part_file_name(part)
                    begin
                        if part.content_type == 'message/rfc822'
                            # An email attached as text
                            # e.g. http://www.whatdotheyknow.com/request/64/response/102
                            part.rfc822_attachment = MailHandler.mail_from_raw_email(part.body, decode=false)
                        elsif part.content_type == 'application/vnd.ms-outlook' || part_filename && AlaveteliFileTypes.filename_to_mimetype(part_filename) == 'application/vnd.ms-outlook'
                            # An email attached as an Outlook file
                            # e.g. http://www.whatdotheyknow.com/request/chinese_names_for_british_politi
                            msg = Mapi::Msg.open(StringIO.new(part.body))
                            part.rfc822_attachment = MailHandler.mail_from_raw_email(msg.to_mime.to_s, decode=false)
                        elsif part.content_type == 'application/ms-tnef'
                            # A set of attachments in a TNEF file
                            part.rfc822_attachment = MailHandler.mail_from_tnef(part.body)
                        end
                    rescue
                        # If attached mail doesn't parse, treat it as text part
                        part.rfc822_attachment = nil
                    else
                        unless part.rfc822_attachment.nil?
                            _count_parts_recursive(part.rfc822_attachment, mail)
                        end
                    end
                    if part.rfc822_attachment.nil?
                        mail.count_parts_count += 1
                        part.url_part_number = mail.count_parts_count
                    end
                end
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