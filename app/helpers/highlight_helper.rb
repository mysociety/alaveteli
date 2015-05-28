# -*- encoding : utf-8 -*-
module HighlightHelper
    include ERB::Util

    # Implementation of rails' highlight that allows regex to be passed to
    # the phrases parameter.
    # https://github.com/rails/rails/pull/11793
    def highlight_matches(text, phrases, options = {})
        text = ActionController::Base.helpers.sanitize(text).try(:html_safe) if options.fetch(:sanitize, true)

        if text.blank? || phrases.blank?
            text
        else
            match = Array(phrases).map do |p|
                Regexp === p ? p.to_s : Regexp.escape(p)
            end.join('|')

            if block_given?
                text.gsub(/(#{match})(?![^<]*?>)/i) { |found| yield found }
            else
                highlighter = options.fetch(:highlighter, '<mark>\1</mark>')
                text.gsub(/(#{match})(?![^<]*?>)/i, highlighter)
            end
         end.html_safe
    end

    # Highlight words, also escapes HTML (other than spans that we add)
    def highlight_words(t, words, html = true)
        if html
            highlight_matches(h(t), words, :highlighter => '<span class="highlight">\1</span>').html_safe
        else
            highlight_matches(t, words, :highlighter => '*\1*')
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

    def excerpt(text, phrase, options = {})
      return unless text && phrase

      separator = options.fetch(:separator, nil) || ""
      case phrase
      when Regexp
        regex = phrase
      else
        regex = /#{Regexp.escape(phrase)}/i
      end

      return unless matches = text.match(regex)
      phrase = matches[0]

      unless separator.empty?
        text.split(separator).each do |value|
          if value.match(regex)
            regex = phrase = value
            break
          end
        end
      end

      first_part, second_part = text.split(phrase, 2)

      prefix, first_part   = cut_excerpt_part(:first, first_part, separator, options)
      postfix, second_part = cut_excerpt_part(:second, second_part, separator, options)

      affix = [first_part, separator, phrase, separator, second_part].join.strip
      [prefix, affix, postfix].join
    end

    private

    def cut_excerpt_part(part_position, part, separator, options)
      return "", "" unless part

      radius   = options.fetch(:radius, 100)
      omission = options.fetch(:omission, "...")

      part = part.split(separator)
      part.delete("")
      affix = part.size > radius ? omission : ""

      part = if part_position == :first
        drop_index = [part.length - radius, 0].max
        part.drop(drop_index)
      else
        part.first(radius)
      end

      return affix, part.join(separator)
    end
end
