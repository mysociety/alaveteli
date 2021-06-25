##
# Helper to translate (via gettext) the strings provided by will_paginate.
#
module PaginationHelper
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
