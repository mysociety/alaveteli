# app/helpers/application_helper.rb:
# Methods added to this helper will be available to all templates in the application.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: application_helper.rb,v 1.6 2007-10-09 20:02:13 francis Exp $

module ApplicationHelper

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
              content_tag(:p, 'Please correct the following and try again.') <<
              content_tag(:ul, error_messages),
            html
          )
        else
          ''
        end
    end

    # Basic date format
    def simple_date(date)
        return date.strftime("%e %B %Y")
    end

end

