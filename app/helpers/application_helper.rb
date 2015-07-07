# -*- encoding : utf-8 -*-
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

    # Some extra date and time formatters
    include DateTimeHelper

    # Site-wide access to configuration settings
    include ConfigHelper

    # Useful for sending emails
    include MailerHelper

    # Extra highlight helpers
    include HighlightHelper

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

    # We only want to cache request lists that have a reasonable chance of not expiring
    # before they're requested again. Don't cache lists returned from specific searches
    # or anything except the first page of results, just the first page of the default
    # views
    def request_list_cache_key
        cacheable_param_list = ['controller', 'action', 'locale', 'view']
        if params.keys.all?{ |key| cacheable_param_list.include?(key) }
            "request-list-#{@view}-#{@locale}"
        else
            nil
        end
    end

    def event_description(event)
        body_link = public_body_link_absolute(event.info_request.public_body)
        user_link = request_user_link_absolute(event.info_request)
        date = simple_date(event.created_at)
        case event.event_type
        when 'sent'
            _('Request sent to {{public_body_name}} by {{info_request_user}} on {{date}}.',
             :public_body_name => body_link,
             :info_request_user => user_link,
             :date => date)
        when 'followup_sent'
            case event.calculated_state
            when 'internal_review'
                _('Internal review request sent to {{public_body_name}} by {{info_request_user}} on {{date}}.',
                 :public_body_name => body_link,
                 :info_request_user => user_link,
                 :date => date)
            when 'waiting_response'
                _('Clarification sent to {{public_body_name}} by {{info_request_user}} on {{date}}.',
                 :public_body_name => body_link,
                 :info_request_user => user_link,
                 :date => date)
            else
                _('Follow up sent to {{public_body_name}} by {{info_request_user}} on {{date}}.',
                 :public_body_name => body_link,
                 :info_request_user => user_link,
                 :date => date)
            end
        when 'response'
            _('Response by {{public_body_name}} to {{info_request_user}} on {{date}}.',
             :public_body_name => body_link,
             :info_request_user => user_link,
             :date => date)
        when 'comment'
            _('Request to {{public_body_name}} by {{info_request_user}}. Annotated by {{event_comment_user}} on {{date}}.',
             :public_body_name => body_link,
             :info_request_user => user_link,
             :event_comment_user => user_link_absolute(event.comment.user),
             :date => date)
        end
    end
end

