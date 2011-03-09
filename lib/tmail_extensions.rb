# lib/tmail_extensions.rb:
# Extensions / fixes to TMail.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: tmail_extensions.rb,v 1.7 2009-10-02 23:31:01 francis Exp $

require 'tmail'
require 'tmail/interface'

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
            file_name = file_name.strip if file_name
            file_name
        end

        # Monkeypatch! Return the name part of from address, or nil if there isn't one
        def from_name_if_present
            if self.from && self.from_addrs[0].name
                return self.from_addrs[0].name
            else
                return nil
            end
        end 

        # Monkeypatch! Generalisation of To:, Cc:
        def envelope_to(default = nil)
            # XXX assumes only one envelope-to, and no parsing needed
            val = self.header_string('envelope-to')
            return val ? [val,] : []
        end

        # Monkeypatch!
        # Bug fix to this function - is for message in humberside-police-odd-mime-type.email
        # Which was originally: https://secure.mysociety.org/admin/foi/request/show_raw_email/11209
        # See test in spec/lib/tmail_extensions.rb
        def set_content_type( str, sub = nil, param = nil )
          if sub
            main, sub = str, sub
          else
            main, sub = str.split(%r</>, 2)
            raise ArgumentError, "sub type missing: #{str.inspect}" unless sub
          end
          if h = @header['content-type']
            h.main_type = main
            h.sub_type  = sub
            h.params.clear if !h.params.nil? # XXX this if statement is the fix # XXX disabled until works with test
          else
            store 'Content-Type', "#{main}/#{sub}"
          end
          @header['content-type'].params.replace param if param
          str
        end
        # Need to make sure this alias calls the Monkeypatch too
        alias content_type= set_content_type

    end

    class Address
        # Monkeypatch! Constructor which makes a TMail::Address given
        # a name and an email
        def Address.address_from_name_and_email(name, email)
            if !MySociety::Validate.is_valid_email(email)
                raise "invalid email " + email + " passed to address_from_name_and_email"    
            end
            if name.nil?
                return TMail::Address.parse(email)
            end
            # Botch an always quoted RFC address, then parse it
            name = name.gsub(/(["\\])/, "\\\\\\1")
            return TMail::Address.parse('"' + name + '" <' + email + '>')
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


