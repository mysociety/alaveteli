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

            # Return a copy of the file name for the mail part
            def get_part_file_name(mail_part)
                part_file_name = mail_part.filename
                part_file_name.nil? ? nil : part_file_name.dup
            end

            # Get the body of a mail part
            def get_part_body(mail_part)
                mail_part.body.decoded
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
                        return first_from.name
                    end
                else
                    return nil
                end
            end

            def get_all_addresses(mail)
                envelope_to = mail['envelope-to'] ? [mail['envelope-to'].value] : []
                ((mail.to || []) +
                (mail.cc || []) +
                (envelope_to || [])).uniq
            end

            # Format
            def address_from_name_and_email(name, email)
                if !MySociety::Validate.is_valid_email(email)
                    raise "invalid email " + email + " passed to address_from_name_and_email"
                end
                if name.nil?
                    return Mail::Address.new(email)
                end
                address = Mail::Address.new
                address.display_name = name
                address.address = email
                address.to_s
            end

            def address_from_string(string)
                Mail::Address.new(string).address
            end
        end
    end
end