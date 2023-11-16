require 'charlock_holmes'
require "net/imap"

class EncodingNormalizationError < StandardError
end

def normalize_string_to_utf8(s, suggested_character_encoding=nil)
  # Make a list of encodings to try:
  to_try = []

  guessed_encoding = if CharlockHolmes::EncodingDetector.detect(s).blank?
    ''
  else
    CharlockHolmes::EncodingDetector.detect(s)[:encoding]
  end
  guessed_encoding ||= ''

  # It's reasonably common for windows-1252 text to be mislabelled
  # as ISO-8859-1, so try that first if charlock_holmes guessed
  # that.  However, it can also easily misidentify UTF-8 strings as
  # ISO-8859-1 so we don't want to go with the guess by default...
  to_try.push guessed_encoding if guessed_encoding.downcase == 'windows-1252'

  to_try.push suggested_character_encoding if suggested_character_encoding
  to_try.push 'UTF-8'
  to_try.push guessed_encoding

  to_try.each do |from_encoding|
    if from_encoding == 'utf-7'
      return Net::IMAP.decode_utf7(s)
    else
      begin
        s.force_encoding from_encoding
        return s.encode('UTF-8') if s.valid_encoding?
      rescue ArgumentError, Encoding::UndefinedConversionError
        # We get this is there are invalid bytes when
        # interpreted as from_encoding at the point of
        # the encode('UTF-8'); move onto the next one...
      rescue Encoding::ConverterNotFoundError,
             Encoding::InvalidByteSequenceError => ex
        raise EncodingNormalizationError, ex.message
      end
    end
  end
  raise EncodingNormalizationError, "Couldn't find a valid character encoding for the string"
end

def convert_string_to_utf8_or_binary(s, suggested_character_encoding=nil)
  # This function exists to help to keep consistent with the
  # behaviour of earlier versions of Alaveteli: in the code as it
  # is, there are situations where it's expected that we generally
  # have a UTF-8 encoded string, but if the source data was
  # unintepretable under any character encoding, the string may be
  # binary data (i.e. invalid UTF-8).  Such a string would then be
  # mangled into valid UTF-8 by _sanitize_text for the purposes of
  # display.

  # This seems unsatisfactory to me - two better alternatives would
  # be either: (a) to mangle the data into valid UTF-8 in this
  # method or (b) to treat the 'text/*' attachment as
  # 'application/octet-stream' instead.  However, for the purposes
  # of the transition to Ruby 1.9 and/or Rails 3 we just want the
  # behaviour to be as similar as possible.

  begin
    result = normalize_string_to_utf8 s, suggested_character_encoding
  rescue EncodingNormalizationError
    result = s.force_encoding 'ASCII-8BIT'
  end
  result
end

StringConversionResult = Struct.new(:string, :scrubbed) do
  alias_method :scrubbed?, :scrubbed
end

def convert_string_to_utf8(s, suggested_character_encoding=nil)
  result = normalize_string_to_utf8 s, suggested_character_encoding
  StringConversionResult.new(result, false)

rescue EncodingNormalizationError
  result = scrub(s)
  StringConversionResult.new(result, true)
end

def scrub(string)
  string = string.force_encoding("utf-8")
  string.valid_encoding? ? string : string.encode("utf-16le", invalid: :replace, replace: "").encode("utf-8")
end

def log_text_details(message, text)
  STDERR.puts "#{message}, we have text: #{text}, of class #{text.class} and encoding #{text.encoding}"
  filename = "/var/tmp/#{Digest::MD5.hexdigest(text)}.txt"
  File.open(filename, "wb") { |f| f.write text }
  STDERR.puts "#{message}, the filename is: #{filename}"
end
