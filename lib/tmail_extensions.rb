# models/request_mailer.rb:
# Extensions / fixes to TMail.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: tmail_extensions.rb,v 1.3 2009-04-08 07:31:08 francis Exp $

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
        # Monkeypatch! Constructor which makes a TMail::Address given
        # a name and an email
        def Address.address_from_name_and_email(name, email)
            # Botch an always quoted RFC address, then parse it
            name = name.gsub(/(["\\])/, "\\\\\\1")
            TMail::Address.parse('"' + name + '" <' + email + '>')
        end
    end

    module TextUtils
        # Monkeypatch! Much more aggressive list of characters to cause quoting 
        # than in normal TMail. e.g. Have found real cases where @ needs quoting.
        # We list characters to allow, rather than characters not to allow.
        NEW_PHRASE_UNSAFE=/[^A-Za-z0-9!#\$%&'*+\-\/=?^_`{|}~ ]/n
        def quote_phrase( str )
          (NEW_PHRASE_UNSAFE === str) ? dquote(str) : str
        end
    end
end


