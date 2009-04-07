# models/request_mailer.rb:
# Extensions / fixes to TMail.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: tmail_extensions.rb,v 1.1 2009-04-07 16:23:28 francis Exp $

# Monkeypatch!

# These mainly used in app/models/incoming_message.rb
module TMail
    class Mail
        # Monkeypatch! (check to see if this becomes a standard function in
        # TMail::Mail, then use that, whatever it is called)
        def self.get_part_file_name(part)
            file_name = (part['content-location'] &&
                          part['content-location'].body) ||
                        part.sub_header("content-type", "name") ||
                        part.sub_header("content-disposition", "filename")
        end
    end

    class Address
        # Monkeypatch!
        def Address.encode_quoted_string(text)
            # XXX have added space to this, so we don't excessive quoting
            if text.match(/[^A-Za-z0-9!#\$%&'*+\-\/=?^_`{|}~ ]/)
                # Contains characters which aren't valid in atoms, so make a
                # quoted-pair instead.
                text.gsub!(/(["\\])/, "\\\\\\1")
                text = '"' + text + '"'
            end
            return text
        end

        # Monkeypatch!
        def quoted_full
            if self.name
                Address.encode_quoted_string(self.name) + " <" + self.spec + ">"
            else
                self.spec
            end
        end
    end
end


