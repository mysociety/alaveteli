# app/helpers/application_helper.rb:
# Methods added to this helper will be available to all views (i.e. templates)
# in the application.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

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

          error_messages = "".html_safe
          for object in objects
              object.errors.each do |attr, message|
                  error_messages << content_tag(:li, h(message))
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
            highlight(h(t), words, :highlighter => '<span class="highlight">\1</span>').html_safe
        else
            highlight(t, words, :highlighter => '*\1*')
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

    def locale_name(locale)
        return LanguageNames::get_language_name(locale)
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

    # Note that if the admin interface is proxied via another server, we can't
    # rely on a sesssion being shared between the front end and admin interface,
    # so need to check the status of the user.
    def is_admin?
      return !session[:using_admin].nil? || (!@user.nil? && @user.super?)
    end

    def cache_if_caching_fragments(*args, &block)
        if AlaveteliConfiguration::cache_fragments
            cache(*args) { yield }
        else
            yield
        end
    end
end

