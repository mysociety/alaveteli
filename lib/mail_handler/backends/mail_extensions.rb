# -*- encoding : utf-8 -*-
require 'mail/message'
require 'mail/part'
require 'mail/fields/common/parameter_hash'
module Mail
    class Message
        attr_accessor :url_part_number
        attr_accessor :rfc822_attachment # when a whole email message is attached as text
        attr_accessor :within_rfc822_attachment # for parts within a message attached as text (for getting subject mainly)
        attr_accessor :count_parts_count
        attr_accessor :count_first_uudecode_count
    end

    class Part < Message
        def inline?
          header[:content_disposition].disposition_type == 'inline' if header[:content_disposition] rescue false
        end
    end

    # A patched version of the parameter hash that handles nil values without throwing
    # an error.
    class ParameterHash < IndifferentHash

        def encoded
          map.sort { |a,b| a.first.to_s <=> b.first.to_s }.map do |key_name, value|
            # The replacement of this commented out line is the change
            # unless value.ascii_only?
            unless value.nil? || value.ascii_only?
              value = Mail::Encodings.param_encode(value)
              key_name = "#{key_name}*"
            end
            %Q{#{key_name}=#{quote_token(value)}}
          end.join(";\r\n\s")
        end
    end

    # HACK: Backport encoding fixes for Ruby 1.8 from Mail 2.5
    # Can be removed when we no longer support Ruby 1.8
    class Ruby18

        def self.b_value_decode(str)
            match = str.match(/\=\?(.+)?\?[Bb]\?(.+)?\?\=/m)
            if match
                encoding = match[1]
                str = Ruby18.decode_base64(match[2])
                # Adding and removing trailing spaces is a workaround
                # for Iconv.conv throwing an exception if it finds an
                # invalid character at the end of the string, even
                # with UTF-8//IGNORE:
                # http://po-ru.com/diary/fixing-invalid-utf-8-in-ruby-revisited/
                begin
                    str = Iconv.conv('UTF-8//IGNORE', fix_encoding(encoding), str + "    ")[0...-4]
                rescue Iconv::InvalidEncoding
                end
            end
            str
        end

        def self.q_value_decode(str)
          match = str.match(/\=\?(.+)?\?[Qq]\?(.+)?\?\=/m)
          if match
              encoding = match[1]
              string = match[2].gsub(/_/, '=20')
              # Remove trailing = if it exists in a Q encoding
              string = string.sub(/\=$/, '')
              str = Encodings::QuotedPrintable.decode(string)
              # Adding and removing trailing spaces is a workaround
              # for Iconv.conv throwing an exception if it finds an
              # invalid character at the end of the string, even
              # with UTF-8//IGNORE:
              # http://po-ru.com/diary/fixing-invalid-utf-8-in-ruby-revisited/
              str = Iconv.conv('UTF-8//IGNORE', fix_encoding(encoding), str + "    ")[0...-4]
          end
          str
        end

        private

        def self.fix_encoding(encoding)
            case encoding.upcase
            when 'UTF8'
                'UTF-8'
            else
                encoding
            end
        end
    end
    class Ruby19

        def self.b_value_decode(str)
          match = str.match(/\=\?(.+)?\?[Bb]\?(.+)?\?\=/m)
          if match
            charset = match[1]
            str = Ruby19.decode_base64(match[2])
            # Rescue an ArgumentError arising from an unknown encoding.
            begin
                str.force_encoding(pick_encoding(charset))
            rescue ArgumentError
            end
          end
          decoded = str.encode("utf-8", :invalid => :replace, :replace => "")
          decoded.valid_encoding? ? decoded : decoded.encode("utf-16le", :invalid => :replace, :replace => "").encode("utf-8")
        end

    end

end
