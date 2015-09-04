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

  # Monkeypatch of method from mail gem to rescue from an unknown encoding
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
