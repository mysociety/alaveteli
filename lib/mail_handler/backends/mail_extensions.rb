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
      match = str.match(/\=\?(.+)?\?[Bb]\?(.*)\?\=/m)
      if match
        charset = match[1]
        str = Ruby19.decode_base64(match[2])
        # The commented line below is the actual implementation in a217776
        # (https://git.io/vozPG) but we don't have a `charset_encoder` object
        # available, so revert to the behaviour of the default
        # Mail::Ruby19::StrictCharsetEncoder#encode (https://git.io/vozXb).
        # str = charset_encoder.encode(str, charset)
        str.force_encoding(Mail::Ruby19.pick_encoding(charset))
      end
      decoded = str.encode(Encoding::UTF_8, :undef => :replace, :invalid => :replace, :replace => "")
      decoded.valid_encoding? ? decoded : decoded.encode(Encoding::UTF_16LE, :invalid => :replace, :replace => "").encode(Encoding::UTF_8)
    rescue Encoding::UndefinedConversionError, ArgumentError, Encoding::ConverterNotFoundError
      warn "Encoding conversion failed #{$!}"
      str.dup.force_encoding(Encoding::UTF_8)
    end

  end

  module Encodings

    def Encodings.collapse_adjacent_encodings(str)
      lines = str.split(/(\?\=)\s*/).each_slice(2).map(&:join).each_slice(2).map(&:join)
      results = []
      previous_encoding = nil

      lines.each do |line|
        encoding = split_value_encoding_from_string(line)
        return lines if results.empty? && encoding == "B"

        if encoding == previous_encoding
          line = results.pop + line
          line.gsub!(/\?\=\=\?.+?\?[QqBb]\?/m, '')
        end

        previous_encoding = encoding
        results << line
      end

      results
    end

  end

end
