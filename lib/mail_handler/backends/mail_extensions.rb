require 'mail/message'
require 'mail/fields/common/parameter_hash'
module Mail
    class Message
        attr_accessor :url_part_number
        attr_accessor :rfc822_attachment # when a whole email message is attached as text
        attr_accessor :within_rfc822_attachment # for parts within a message attached as text (for getting subject mainly)
        attr_accessor :count_parts_count
        attr_accessor :count_first_uudecode_count

        # A patched version of the message initializer to work around a bug where stripping the original
        # input removes meaningful spaces - e.g. in the case of uuencoded bodies.
        def initialize(*args, &block)
            @body = nil
            @body_raw = nil
            @separate_parts = false
            @text_part = nil
            @html_part = nil
            @errors = nil
            @header = nil
            @charset = 'UTF-8'
            @defaulted_charset = true

            @perform_deliveries = true
            @raise_delivery_errors = true

            @delivery_handler = nil

            @delivery_method = Mail.delivery_method.dup

            @transport_encoding = Mail::Encodings.get_encoding('7bit')

            @mark_for_delete = false

            if args.flatten.first.respond_to?(:each_pair)
                init_with_hash(args.flatten.first)
            else
                # The replacement of this commented out line is the change.
                # init_with_string(args.flatten[0].to_s.strip)
                init_with_string(args.flatten[0].to_s)
            end

            if block_given?
                instance_eval(&block)
            end

            self
        end

        # HACK: Backported from Mail 2.5 for Ruby 1.8 support
        # Can be removed when we no longer support Ruby 1.8
        def to_yaml(opts = {})
          hash = {}
          hash['headers'] = {}
          header.fields.each do |field|
            hash['headers'][field.name] = field.value
          end
          hash['delivery_handler'] = delivery_handler.to_s if delivery_handler
          hash['transport_encoding'] = transport_encoding.to_s
          special_variables = [:@header, :@delivery_handler, :@transport_encoding]
          if multipart?
            hash['multipart_body'] = []
            body.parts.map { |part| hash['multipart_body'] << part.to_yaml }
            special_variables.push(:@body, :@text_part, :@html_part)
          end
          (instance_variables.map(&:to_sym) - special_variables).each do |var|
            hash[var.to_s] = instance_variable_get(var)
          end
          hash.to_yaml(opts)
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
        def Ruby18.b_value_decode(str)
            match = str.match(/\=\?(.+)?\?[Bb]\?(.+)?\?\=/m)
            if match
                encoding = match[1]
                str = Ruby18.decode_base64(match[2])
                str = Iconv.conv('UTF-8//IGNORE', fix_encoding(encoding), str)
            end
            str
        end

        def Ruby18.q_value_decode(str)
          match = str.match(/\=\?(.+)?\?[Qq]\?(.+)?\?\=/m)
          if match
              encoding = match[1]
              string = match[2].gsub(/_/, '=20')
              # Remove trailing = if it exists in a Q encoding
              string = string.sub(/\=$/, '')
              str = Encodings::QuotedPrintable.decode(string)
              str = Iconv.conv('UTF-8//IGNORE', fix_encoding(encoding), str)
          end
          str
        end

        private

        def Ruby18.fix_encoding(encoding)
            case encoding.upcase
            when 'UTF8'
                'UTF-8'
            else
                encoding
            end
        end
    end

    # HACK: Backport encoding fixes for Ruby 1.9 from Mail 2.5
    # Can be removed when Rails relies on Mail > 2.5
    class Ruby19
        def Ruby19.b_value_decode(str)
            match = str.match(/\=\?(.+)?\?[Bb]\?(.+)?\?\=/m)
            if match
                encoding = match[1]
                str = Ruby19.decode_base64(match[2])
                str.force_encoding(fix_encoding(encoding))
            end
            decoded = str.encode("utf-8", :invalid => :replace, :replace => "")
            decoded.valid_encoding? ? decoded : decoded.encode("utf-16le", :invalid => :replace, :replace => "").encode("utf-8")
        end

        def Ruby19.q_value_decode(str)
            match = str.match(/\=\?(.+)?\?[Qq]\?(.+)?\?\=/m)
            if match
                encoding = match[1]
                str = Encodings::QuotedPrintable.decode(match[2])
                str.force_encoding(fix_encoding(encoding))
            end
            decoded = str.encode("utf-8", :invalid => :replace, :replace => "")
            decoded.valid_encoding? ? decoded : decoded.encode("utf-16le", :invalid => :replace, :replace => "").encode("utf-8")
        end

        # mails somtimes includes invalid encodings like iso885915 or utf8 so we transform them to iso885915 or utf8
        # TODO: add this as a test somewhere
        # Encoding.list.map{|e| [e.to_s.upcase==fix_encoding(e.to_s.downcase.gsub("-", "")), e.to_s] }.select {|a,b| !b}
        #  Encoding.list.map{|e| [e.to_s==fix_encoding(e.to_s), e.to_s] }.select {|a,b| !b}
        def Ruby19.fix_encoding(encoding)
            case encoding
                # ISO-8859-15, ISO-2022-JP and alike
                when /iso-?(\d{4})-?(\w{1,2})/i then return "ISO-#{$1}-#{$2}"
                # "ISO-2022-JP-KDDI"  and alike
                when /iso-?(\d{4})-?(\w{1,2})-?(\w*)/i then return "ISO-#{$1}-#{$2}-#{$3}"
                # UTF-8, UTF-32BE and alike
                when /utf-?(\d{1,2})?(\w{1,2})/i then return "UTF-#{$1}#{$2}"
                # Windows-1252 and alike
                when /Windows-?(.*)/i then return "Windows-#{$1}"
                #more aliases to be added if needed
                else return encoding
            end
        end
    end
end
