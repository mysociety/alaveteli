module HighlightHelper

    include ERB::Util

    # from http://norm.al/2009/04/14/list-of-english-stop-words/
    STOP_WORDS = %w(a about above across after afterwards again against all almost alone along already also although always am among amongst amoungst amount an and another any anyhow anyone anything anyway anywhere are around as at back be became because become becomes becoming been before beforehand behind being below beside besides between beyond bill both bottom but by call can cannot cant co computer con could couldnt cry de describe detail do done down due during each eg eight either eleven else elsewhere empty enough etc even ever every everyone everything everywhere except few fifteen fifty fill find fire first five for former formerly forty found four from front full further get give go had has hasnt have he hence her here hereafter hereby herein hereupon hers herself him himself his how however hundred i ie if in inc indeed interest into is it its itse” keep last latter latterly least less ltd made many may me meanwhile might mill mine more moreover most mostly move much must my myse” name namely neither never nevertheless next nine no nobody none noone nor not nothing now nowhere of off often on once one only onto or other others otherwise our ours ourselves out over own part per perhaps please put rather re same see seem seemed seeming seems serious several she should show side since sincere six sixty so some somehow someone something sometime sometimes somewhere still such system take ten than that the their them themselves then thence there thereafter thereby therefore therein thereupon these they thick thin third this those though three through throughout thru thus to together too top toward towards twelve twenty two un under until up upon us very via was we well were what whatever when whence whenever where whereafter whereas whereby wherein whereupon wherever whether which while whither who whoever whole whom whose why will with within without would yet you your yours yourself yourselves)

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
        phrases = phrases - STOP_WORDS
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
