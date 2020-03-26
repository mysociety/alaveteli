unless rails_upgrade?
  ##
  # Hotfix for CVE-2020-5267. Backport for Rails 5.1
  #
  module ActionView::Helpers::JavaScriptHelper
    JS_ESCAPE_MAP["`"] = "\\`"
    JS_ESCAPE_MAP["$"] = "\\$"

    def escape_javascript(javascript)
      javascript = javascript.to_s
      if javascript.empty?
        result = ""
      else
        result = javascript.gsub(
          /(\\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"']|[`]|[$])/u,
          JS_ESCAPE_MAP
        )
      end
      javascript.html_safe? ? result.html_safe : result
    end
  end
end
