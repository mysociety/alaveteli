##
# Helper for rendering pagination
#
module PaginationHelper
  def will_paginate(collection, options = {})
    super(collection, options.merge(renderer: CustomRenderer))
  end

  ##
  # Custom pagination link renderer which injects nofollow for pages over 20
  #
  class CustomRenderer < WillPaginate::ActionView::LinkRenderer
    def rel_value(page)
      rel = [*super]
      rel << 'nofollow' if page > 20
      rel.join(' ')
    end
  end

  ##
  # Helper to translate (via gettext) the strings provided by will_paginate.
  #
  def will_paginate_translate(key, options = {})
    case key
    when :previous_label then _("&#8592; Previous")
    when :next_label then _("Next &#8594;")
    when :page_gap then "&hellip;"
    when :container_aria_label then _("Pagination")
    when :page_aria_label then _("Page {{page}}", options)
    else super
    end
  end
end
