# -*- encoding : utf-8 -*-

# Backported fix for CVE-2016-6316
# https://groups.google.com/forum/#!msg/ruby-security-ann/8B2iV2tPRSE/JkjCJkSoCgAJ

module ActionView::Helpers::TagHelper

  private

  def tag_option(key, value, escape)
    if value.is_a?(Array)
      value = escape ? safe_join(value, " ") : value.join(" ")
    else
      value = escape ? ERB::Util.html_escape(value) : value.to_s
    end
    %(#{key}="#{value.gsub('"'.freeze, '&quot;'.freeze)}")
  end

end
