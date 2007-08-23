# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

    # This was the best solution I could find to this, yeuch.
    # http://www.ruby-forum.com/topic/88857
    def stylesheet_link_tag_html4( _n )
        return stylesheet_link_tag( _n ).gsub( ' />', '>' )
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
              content_tag(:p, 'Please correct the following and try again.') <<
              content_tag(:ul, error_messages),
            html
          )
        else
          ''
        end
    end


end
