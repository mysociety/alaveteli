require 'unidecoder'

module Alaveteli
  module Format
    # Simplified a name to something usable in a URL
    def self.simplify_url_part(text, default_name, max_len = nil)
      text = text.downcase # this also clones the string, if we use downcase! we modify the original
      text = text.unicode_normalize(:nfkd)
      text = text.to_ascii.downcase

      text.gsub!(/(\s|-|_)/, "_")
      text.gsub!(/[^a-z0-9_]/, "")
      text.gsub!(/_+/, "_")
      text.gsub!(/^_*/, "")
      text.gsub!(/_*$/, "")

      # If required, trim down to size
      if not max_len.nil?
        if text.size > max_len
          text = text[0..(max_len-1)]
        end
        # removing trailing _
        text.gsub!(/_*$/, "")
      end
      # Don't allow short (zero length!), or all numeric (clashes with identifiers)
      if text.size < 1 || text.match(/^[0-9]+$/)
        text = default_name # just do "user_1", "user_2" etc.
      end

      text
    end
  end
end
