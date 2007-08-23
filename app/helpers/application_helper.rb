# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

    # This was the best solution I could find to this, yeuch.
    # http://www.ruby-forum.com/topic/88857
    def stylesheet_link_tag_html4( _n )
        return stylesheet_link_tag( _n ).gsub( ' />', '>' )
    end

end
