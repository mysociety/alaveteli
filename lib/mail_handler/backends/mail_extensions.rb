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

end
