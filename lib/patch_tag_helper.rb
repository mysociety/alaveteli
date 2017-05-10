# -*- encoding : utf-8 -*-

# Backported fix for CVE-2016-6316
# https://groups.google.com/forum/#!msg/ruby-security-ann/8B2iV2tPRSE/JkjCJkSoCgAJ

module ActionView::Helpers::TagHelper

  private

  def tag_option(key, value, escape)
    if value.is_a?(Array)
      value = escape ? safe_join(value, " ") : value.join(" ")
    else
      value = escape ? ERB::Util.unwrapped_html_escape(value) : value.to_s
    end
    %(#{key}="#{value.gsub('"'.freeze, '&quot;'.freeze)}")
  end

end


module ERB::Util

  # Copied in from Rails 4.2 as it doesn't yet exist in 4.1

  # HTML escapes strings but doesn't wrap them with an ActiveSupport::SafeBuffer.
  # This method is not for public consumption! Seriously!
  def unwrapped_html_escape(s) # :nodoc:
    s = s.to_s
    if s.html_safe?
      s
    else
      s.gsub(HTML_ESCAPE_REGEXP, HTML_ESCAPE)
    end
  end
  module_function :unwrapped_html_escape

end
