# app/helpers/application_helper.rb:
# Methods added to this helper will be available to all views (i.e. templates)
# in the application.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/

require 'languages'

module ApplicationHelper
    # URL generating functions are needed by all controllers (for redirects),
    # views (for links) and mailers (for use in emails), so include them into
    # all of all.
    include LinkToHelper

    # Site-wide access to configuration settings
    include ConfigHelper

    # Useful for sending emails
    include MailerHelper

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

          error_messages = []
          for object in objects
              object.errors.each do |attr, message|
                  error_messages << content_tag(:li, message)
              end
          end

          content_tag(:div,
              content_tag(:ul, error_messages),
            html
          )
        else
            ''
        end
    end

    # Highlight words, also escapes HTML (other than spans that we add)
    def highlight_words(t, words, html = true)
        if html
            t = h(t)
        end
        if html
            t = highlight(t, words, '<span class="highlight">\1</span>')
        else
            t = highlight(t, words, '*\1*')
        end
        return t
    end
    def highlight_and_excerpt(t, words, excount, html = true)
        newt = excerpt(t, words[0], excount)
        if not newt
            newt = excerpt(t, '', excount)
        end
        t = newt
        t = highlight_words(t, words, html)
        return t
    end

    def locale_name(locale)
        return LanguageNames::get_language_name(locale)
    end

    # Use our own algorithm for finding path of cache
    def foi_cache(name = {}, options = nil, &block)
        if @controller.perform_caching
            key = name.merge(:only_path => true)
            key_path = @controller.foi_fragment_cache_path(key)

            if @controller.foi_fragment_cache_exists?(key_path)
                cached = @controller.foi_fragment_cache_read(key_path)
                output_buffer.concat(cached)
                return
            end

            pos = output_buffer.length
            content = block.call
            @controller.foi_fragment_cache_write(key_path, output_buffer[pos..-1])
        else
            block.call
        end
    end
    # (unfortunately) ugly way of getting id of generated form element
    # ids
    # see http://chrisblunt.com/2009/10/12/rails-getting-the-id-of-form-fields-inside-a-fields_for-block/
    def sanitized_object_name(object_name)
        object_name.gsub(/\]\[|[^-a-zA-Z0-9:.]/,"_").sub(/_$/,"")
    end

    def sanitized_method_name(method_name)
        method_name.sub(/\?$/, "")
    end

    def form_tag_id(object_name, method_name, locale=nil)
	if locale.nil?
            return "#{sanitized_object_name(object_name.to_s)}_#{sanitized_method_name(method_name.to_s)}"
        else
            return "#{sanitized_object_name(object_name.to_s)}_#{sanitized_method_name(method_name.to_s)}__#{locale.to_s}"
        end
    end

    def admin_value(v)
      if v.nil?
        nil
      elsif v.instance_of?(Time)
        admin_date(v)
      else
        h(v)
      end
    end

    def admin_date(date)
        ago_text = _('{{length_of_time}} ago', :length_of_time => time_ago_in_words(date))
        exact_date = I18n.l(date, :format => "%e %B %Y %H:%M:%S")
        return "#{exact_date} (#{ago_text})"
    end

    def is_admin?
        return !session[:using_admin].nil? || (!@user.nil? && @user.admin_level == "super")
    end

end

