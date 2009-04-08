# models/request_mailer.rb:
# Extensions / fixes to TMail.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: tmail_extensions.rb,v 1.2 2009-04-08 05:29:36 francis Exp $

# Monkeypatch!

# These mainly used in app/models/incoming_message.rb
module TMail
    class Mail
        # Monkeypatch! (check to see if this becomes a standard function in
        # TMail::Mail, then use that, whatever it is called)
        def Mail.get_part_file_name(part)
            file_name = (part['content-location'] &&
                          part['content-location'].body) ||
                        part.sub_header("content-type", "name") ||
                        part.sub_header("content-disposition", "filename")
        end

        # Monkeypatch! Return the name part of from address, or nil if there isn't one
        def from_name_if_present
            if self.from && self.from_addrs[0].name
                return self.from_addrs[0].name
            else
                return nil
            end
        end 

    end

    class Address
        # Monkeypatch!
        def Address.encode_quoted_string(text)
            # XXX have added space to this, so we don't excessive quoting
            if text.match(/[^A-Za-z0-9!#\$%&'*+\-\/=?^_`{|}~ ]/)
                # Contains characters which aren't valid in atoms, so make a
                # quoted-pair instead.
                text = text.gsub(/(["\\])/, "\\\\\\1")
                text = '"' + text + '"'
            end
            return text
        end

        # Monkeypatch!
        def full_quoted_address
            if self.name
                # sanitise name - some mail servers can't cope with @ in the name part
                name = self.name.gsub(/@/, " ")
                Address.encode_quoted_string(name) + " <" + self.spec + ">"
            else
                self.spec
            end
        end
    end
end


