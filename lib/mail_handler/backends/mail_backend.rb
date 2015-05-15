# -*- encoding : utf-8 -*-
require 'mail'
require 'mapi/msg'
require 'mapi/convert'

module Mail
    class Message

        # The behaviour of the 'to' and 'cc' methods have changed
        # between TMail and Mail; this monkey-patching restores the
        # TMail behaviour.  The key difference is that when there's an
        # invalid address, e.g. '<foo@example.org', Mail returns the
        # string as an ActiveSupport::Multibyte::Chars, whereas
        # previously TMail would return nil.

        alias_method :old_to, :to
        alias_method :old_cc, :cc

        def clean_addresses(old_method, val)
            old_result = self.send(old_method, val)
            old_result.class == Mail::AddressContainer ? old_result : nil
        end

        def to(val = nil)
            self.clean_addresses :old_to, val
        end

        def cc(val = nil)
            self.clean_addresses :old_cc, val
        end

    end
end

module MailHandler
    module Backends
        module MailBackend

            def backend()
                'Mail'
            end

            def mail_from_raw_email(data)
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

            # Returns an outlook message as a Mail object
            def mail_from_outlook(content)
                msg = Mapi::Msg.open(StringIO.new(content))
                mail = mail_from_raw_email(msg.to_mime.to_s)
                mail.ready_to_send!
                mail
            end

            # Return a copy of the file name for the mail part
            def get_part_file_name(part)
                part_file_name = part.filename
                part_file_name.nil? ? nil : part_file_name.dup
            end

            # Get the body of a mail part
            def get_part_body(part)
                decoded = part.body.decoded
                if part.content_type =~ /^text\//
                    decoded = convert_string_to_utf8_or_binary decoded, part.charset
                end
                decoded
            end

            # Return the first from field if any
            def first_from(mail)
                if mail[:from]
                    begin
                        mail[:from].addrs[0]
                        mail[:from].decoded
                        return mail[:from].addrs[0]
                    rescue
                        return mail[:from].value
                    end
                else
                    nil
                end
            end

            # Return the first from address if any
            def get_from_address(mail)
                first_from = first_from(mail)
                if first_from
                    if first_from.is_a?(String)
                        return nil
                    else
                        return first_from.address
                    end
                else
                    return nil
                end
            end

            # Return the first from name if any
            def get_from_name(mail)
                first_from = first_from(mail)
                if first_from
                    if first_from.is_a?(String)
                        return nil
                    else
                        return (first_from.display_name || nil)
                    end
                else
                    return nil
                end
            end

            def get_all_addresses(mail)
                envelope_to = mail['envelope-to'] ? [mail['envelope-to'].value.to_s] : []
                ((mail.to || []) +
                (mail.cc || []) +
                (envelope_to || [])).uniq
            end

            def empty_return_path?(mail)
                return false if mail['return-path'].nil?
                return true if mail['return-path'].value.blank?
                return false
            end

            def get_auto_submitted(mail)
                mail['auto-submitted'] ? mail['auto-submitted'].value : nil
            end

            def get_content_type(part)
                part.content_type ? part.content_type.split(';')[0] : nil
            end

            def get_header_string(header, mail)
                mail.header[header] ? mail.header[header].to_s : nil
            end

            # Detects whether a mail part is an Outlook email
            def is_outlook?(part)
                filename = get_part_file_name(part)
                return true if get_content_type(part) == 'application/vnd.ms-outlook'
                if filename && AlaveteliFileTypes.filename_to_mimetype(filename) == 'application/vnd.ms-outlook'
                    return true
                end
                return false
            end

            # Convert a mail part which is an attached mail in one of
            # several formats into a mail object and set it as the
            # rfc822_attachment on the part. If the mail part can't be
            # converted, the content type on the part is updated to
            # 'text/plain' for an RFC822 attachment, and 'application/octet-stream'
            # for other types
            def decode_attached_part(part, parent_mail)
                if get_content_type(part) == 'message/rfc822'
                    # An email attached as text
                    part.rfc822_attachment = mail_from_raw_email(part.body)
                    if part.rfc822_attachment.nil?
                        # Attached mail didn't parse, so treat as text
                        part.content_type = 'text/plain'
                    end
                elsif is_outlook?(part)
                    part.rfc822_attachment = mail_from_outlook(part.body.decoded)
                    if part.rfc822_attachment.nil?
                         # Attached mail didn't parse, so treat as binary
                         part.content_type = 'application/octet-stream'
                    end
                elsif get_content_type(part) == 'application/ms-tnef'
                    # A set of attachments in a TNEF file
                    begin
                        part.rfc822_attachment = mail_from_tnef(part.body.decoded)
                        if part.rfc822_attachment.nil?
                            # Attached mail didn't parse, so treat as binary
                            part.content_type = 'application/octet-stream'
                        end
                    rescue TNEFParsingError
                        part.rfc822_attachment = nil
                        part.content_type = 'application/octet-stream'
                    end
                end
                if part.rfc822_attachment
                    expand_and_normalize_parts(part.rfc822_attachment, parent_mail)
                end
            end

            # Expand and normalize a mail part recursively. Decodes attached messages into
            # Mail objects wherever possible. Sets a default content type if none is
            # set. Tries to set a more specific content type for binary content types.
            def expand_and_normalize_parts(part, parent_mail)
                if part.multipart?
                  part.parts.each{ |sub_part| expand_and_normalize_parts(sub_part, parent_mail) }
                else
                  part_filename = get_part_file_name(part)
                  if part.has_charset?
                      original_charset = part.charset # save this, because overwriting content_type also resets charset
                  else
                      original_charset = nil
                  end
                  # Don't allow nil content_types
                  if get_content_type(part).nil?
                      part.content_type = 'application/octet-stream'
                  end

                  # PDFs often come with this mime type, fix it up for view code
                  if get_content_type(part) == 'application/octet-stream'
                      part_body = get_part_body(part)
                      calc_mime = AlaveteliFileTypes.filename_and_content_to_mimetype(part_filename,
                                                                                      part_body)
                      if calc_mime
                          part.content_type = calc_mime
                      end
                  end

                  # Use standard content types for Word documents etc.
                  part.content_type = normalise_content_type(get_content_type(part))
                  decode_attached_part(part, parent_mail)
                  if original_charset
                      part.charset = original_charset
                  end
                end
            end

            # Count the parts in a mail part recursively, including any attached messages.
            # Set the count on the parent mail, and set a url_part_number on the part itself.
            # Set the count for the first uudecoded part on the parent mail also.
            def count_parts(part, parent_mail)
                if part.multipart?
                    part.parts.each { |p| count_parts(p, parent_mail) }
                else
                    if part.rfc822_attachment
                        count_parts(part.rfc822_attachment, parent_mail)
                    else
                        parent_mail.count_parts_count += 1
                        part.url_part_number = parent_mail.count_parts_count
                    end
                end
                parent_mail.count_first_uudecode_count = parent_mail.count_parts_count
            end

            # Choose the best part from alternatives
            def choose_best_alternative(mail)
                if mail.parts.any?(&:multipart?)
                    return mail.parts.detect(&:multipart?)
                end
                if mail.html_part
                    return mail.html_part
                elsif mail.text_part
                    return mail.text_part
                else
                    return mail.parts.first
                end
            end

            # Expand and normalize the parts of a mail, select the best part
            # wherever there is an alternative, and then count the returned
            # leaves and assign url_part values to them
            def get_attachment_leaves(mail)
                # TODO: Most of these methods are modifying in place! :(
                expand_and_normalize_parts(mail, mail)
                leaves = _get_attachment_leaves_recursive(mail, nil, mail)
                mail.count_parts_count = 0
                count_parts(mail, mail)
                return leaves
            end

            # Recurse through a mail part, selecting the best part wherever there is
            # an alternative
            def _get_attachment_leaves_recursive(part, within_rfc822_attachment, parent_mail)
                leaves_found = []
                if part.multipart?
                    if part.parts.size == 0
                        # This is typically caused by a missing final
                        # MIME boundary, in which case the text of the
                        # message (including the opening MIME
                        # boundary) is in part.body, so just add this
                        # part as a leaf and treat it as text/plain:
                        part.content_type = "text/plain"
                        leaves_found += [part]
                    elsif part.sub_type == 'alternative'
                        best_part = choose_best_alternative(part)
                        leaves_found += _get_attachment_leaves_recursive(best_part,
                                                                         within_rfc822_attachment,
                                                                         parent_mail)
                    else
                        # Add all parts
                        part.parts.each do |sub_part|
                            leaves_found += _get_attachment_leaves_recursive(sub_part,
                                                                             within_rfc822_attachment,
                                                                             parent_mail)
                        end
                    end
                else
                    # Add all the parts of a decoded attached message
                    if part.rfc822_attachment
                        leaves_found += _get_attachment_leaves_recursive(part.rfc822_attachment,
                                                                         part.rfc822_attachment,
                                                                         parent_mail)
                    else
                        # Store leaf
                        part.within_rfc822_attachment = within_rfc822_attachment
                        leaves_found += [part]
                    end
                end
                return leaves_found
            end

            # Add selected useful headers from an attached message to its body
            def extract_attached_message_headers(leaf)
                body = get_part_body(leaf)
                # Test to see if we are in the first part of the attached
                # RFC822 message and it is text, if so add headers.
                if leaf.within_rfc822_attachment == leaf && get_content_type(leaf) == 'text/plain'
                    headers = ""
                    [ 'Date', 'Subject', 'From', 'To', 'Cc' ].each do |header|
                        if header_value = get_header_string(header, leaf.within_rfc822_attachment)
                            if !header_value.blank?
                                headers = headers + header + ": " + header_value.to_s + "\n"
                            end
                        end
                    end
                    # TODO: call _convert_part_body_to_text here, but need to get charset somehow
                    # e.g. http://www.whatdotheyknow.com/request/1593/response/3088/attach/4/Freedom%20of%20Information%20request%20-%20car%20oval%20sticker:%20Article%2020,%20Convention%20on%20Road%20Traffic%201949.txt
                    body = headers + "\n" + body
                end
                body
            end

            # Generate a hash of the attributes associated with each significant part of a Mail object
            def get_attachment_attributes(mail)
                leaves = get_attachment_leaves(mail)
                attachments = []
                for leaf in leaves
                    body = get_part_body(leaf)
                    if leaf.within_rfc822_attachment
                        within_rfc822_subject = leaf.within_rfc822_attachment.subject
                        body = extract_attached_message_headers(leaf)
                    end
                    leaf_attributes = { :url_part_number => leaf.url_part_number,
                                        :content_type => get_content_type(leaf),
                                        :filename => get_part_file_name(leaf),
                                        :charset => leaf.charset,
                                        :within_rfc822_subject => within_rfc822_subject,
                                        :body => body,
                                        :hexdigest => Digest::MD5.hexdigest(body) }
                    attachments << leaf_attributes
                end
                return attachments
            end

            # Format
            def address_from_name_and_email(name, email)
                if !MySociety::Validate.is_valid_email(email)
                    raise "invalid email " + email + " passed to address_from_name_and_email"
                end
                if name.nil?
                    return Mail::Address.new(email).to_s
                end
                address = Mail::Address.new
                address.display_name = name
                address.address = email
                address.to_s
            end

            def address_from_string(string)
                mail = Mail.new
                mail.from = string
                mail.from[0]
            end
        end
    end
end
