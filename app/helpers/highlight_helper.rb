module HighlightHelper

  include ERB::Util

    # implementation of rails' highlight that respects word boundaries
    def do_highlight(text, phrases, *args)
        options = args.extract_options!
        unless args.empty?
            ActiveSupport::Deprecation.warn "Calling highlight with a highlighter as an argument is deprecated. " \
                "Please call with :highlighter => '#{args[0]}' instead.", caller

            options[:highlighter] = args[0] || '<strong class="highlight">\1</strong>'
        end
        options.reverse_merge!(:highlighter => '<strong class="highlight">\1</strong>')

        text = sanitize(text) unless options[:sanitize] == false
        if text.blank? || phrases.blank?
            text
        else
            match = Array(phrases).map { |p| Regexp.escape(p) }.join('|')
            text.gsub(/\b(#{match})\b(?![^<]*?>)/i, options[:highlighter])
        end.html_safe
    end

    # Highlight words, also escapes HTML (other than spans that we add)
    def highlight_words(t, words, html = true)
        if html
            do_highlight(h(t), words, :highlighter => '<span class="highlight">\1</span>').html_safe
        else
            do_highlight(t, words, :highlighter => '*\1*')
        end
    end

    def highlight_and_excerpt(t, words, excount, html = true)
        newt = excerpt(t, words[0], :radius => excount)
        if not newt
            newt = excerpt(t, '', :radius => excount)
        end
        t = newt
        t = highlight_words(t, words, html)
        return t
    end
end
