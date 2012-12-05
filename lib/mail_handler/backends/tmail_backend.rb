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
                    part_filename = get_part_file_name(part)
                    begin
                        if part.content_type == 'message/rfc822'
                            # An email attached as text
                            # e.g. http://www.whatdotheyknow.com/request/64/response/102
                            part.rfc822_attachment = mail_from_raw_email(part.body, decode=false)
                        elsif part.content_type == 'application/vnd.ms-outlook' || part_filename && AlaveteliFileTypes.filename_to_mimetype(part_filename) == 'application/vnd.ms-outlook'
                            # An email attached as an Outlook file
                            # e.g. http://www.whatdotheyknow.com/request/chinese_names_for_british_politi
                            msg = Mapi::Msg.open(StringIO.new(part.body))
                            part.rfc822_attachment = mail_from_raw_email(msg.to_mime.to_s, decode=false)
                        elsif part.content_type == 'application/ms-tnef'
                            # A set of attachments in a TNEF file
                            part.rfc822_attachment = mail_from_tnef(part.body)
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

            def get_attachment_attributes(mail)
                leaves = get_attachment_leaves(mail)
                # XXX we have to call ensure_parts_counted after get_attachment_leaves
                # which is really messy.
                ensure_parts_counted(mail)
                leaves
            end

            # (This risks losing info if the unchosen alternative is the only one to contain
            # useful info, but let's worry about that another time)
            def get_attachment_leaves(mail)
                return _get_attachment_leaves_recursive(mail, mail)
            end
            def _get_attachment_leaves_recursive(curr_mail, parent_mail, within_rfc822_attachment = nil)
                leaves_found = []
                if curr_mail.multipart?
                    if curr_mail.parts.size == 0
                        raise "no parts on multipart mail"
                    end

                    if curr_mail.sub_type == 'alternative'
                        # Choose best part from alternatives
                        best_part = nil
                        # Take the last text/plain one, or else the first one
                        curr_mail.parts.each do |m|
                            if not best_part
                                best_part = m
                            elsif m.content_type == 'text/plain'
                                best_part = m
                            end
                        end
                        # Take an HTML one as even higher priority. (They tend
                        # to render better than text/plain, e.g. don't wrap links here:
                        # http://www.whatdotheyknow.com/request/amount_and_cost_of_freedom_of_in#incoming-72238 )
                        curr_mail.parts.each do |m|
                            if m.content_type == 'text/html'
                                best_part = m
                            end
                        end
                        leaves_found += _get_attachment_leaves_recursive(best_part, parent_mail, within_rfc822_attachment)
                    else
                        # Add all parts
                        curr_mail.parts.each do |m|
                            leaves_found += _get_attachment_leaves_recursive(m, parent_mail, within_rfc822_attachment)
                        end
                    end
                else
                    # XXX Yuck. this section alters various content_types. That puts
                    # it into conflict with ensure_parts_counted which it has to be
                    # called both before and after.  It will fail with cases of
                    # attachments of attachments etc.
                    charset = curr_mail.charset # save this, because overwriting content_type also resets charset
                    # Don't allow nil content_types
                    if curr_mail.content_type.nil?
                        curr_mail.content_type = 'application/octet-stream'
                    end
                    # PDFs often come with this mime type, fix it up for view code
                    if curr_mail.content_type == 'application/octet-stream'
                        part_file_name = get_part_file_name(curr_mail)
                        part_body = get_part_body(curr_mail)
                        calc_mime = AlaveteliFileTypes.filename_and_content_to_mimetype(part_file_name, part_body)
                        if calc_mime
                            curr_mail.content_type = calc_mime
                        end
                    end

                    # Use standard content types for Word documents etc.
                    curr_mail.content_type = normalise_content_type(curr_mail.content_type)
                    if curr_mail.content_type == 'message/rfc822'
                        ensure_parts_counted(parent_mail) # fills in rfc822_attachment variable
                        if curr_mail.rfc822_attachment.nil?
                            # Attached mail didn't parse, so treat as text
                            curr_mail.content_type = 'text/plain'
                        end
                    end
                    if curr_mail.content_type == 'application/vnd.ms-outlook' || curr_mail.content_type == 'application/ms-tnef'
                        ensure_parts_counted(parent_mail) # fills in rfc822_attachment variable
                        if curr_mail.rfc822_attachment.nil?
                            # Attached mail didn't parse, so treat as binary
                            curr_mail.content_type = 'application/octet-stream'
                        end
                    end
                    # If the part is an attachment of email
                    if curr_mail.content_type == 'message/rfc822' || curr_mail.content_type == 'application/vnd.ms-outlook' || curr_mail.content_type == 'application/ms-tnef'
                        ensure_parts_counted(parent_mail) # fills in rfc822_attachment variable
                        leaves_found += _get_attachment_leaves_recursive(curr_mail.rfc822_attachment, parent_mail, curr_mail.rfc822_attachment)
                    else
                        # Store leaf
                        curr_mail.within_rfc822_attachment = within_rfc822_attachment
                        leaves_found += [curr_mail]
                    end
                    # restore original charset
                    curr_mail.charset = charset
                end
                return leaves_found
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