# app/helpers/application_helper.rb:
# Methods added to this helper will be available to all views (i.e. templates)
# in the application.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: application_helper.rb,v 1.17 2008-03-06 21:49:33 francis Exp $

module ApplicationHelper
    # URL generating functions are needed by all controllers (for redirects)
    # views (for links), so include them into all of both.
    include LinkToHelper

    # Contact email address
    def contact_email
        MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost') 
    end

    # Copied from error_messages_for in active_record_helper.rb
    def foi_error_messages_for(*params)
        options = params.last.is_a?(Hash) ? params.pop.symbolize_keys : {}
        objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
        count   = objects.inject(0) {|sum, object| sum + object.errors.count }
        unless count.zero?
          html = {}
          [:id, :class].each do |key|
            if options.include?(key)
              value = options[key]
              html[key] = value unless value.blank?
            else
              html[key] = 'errorExplanation'
            end
          end
          error_messages = objects.map {|object| object.errors.full_messages.map {|msg| content_tag(:li, msg) } }
          content_tag(:div,
              content_tag(:ul, error_messages),
            html
          )
        else
          ''
        end
    end

    # Used for search results
    def excerpt_and_highlight(text, words, count = 150)
        # Find at least one word if we can
        t = nil
        for word in words
            t = excerpt(text, word, count)
            if not t.nil?
                break
            end
        end
        if t.nil?
            t = excerpt(text, "", count * 2)
        end

        # Highlight all the words, escaping HTML also
        t = highlight_words(t, words)
        return t
    end
    # Highlight words, also escapes HTML (other than spans that we add)
    def highlight_words(t, words)
        t = h(t)
        t = highlight(t, words, '<span class="highlight">\1</span>')
        return t
    end
end

