# Helpers for handling prominence in the admin interface
module Admin::ProminenceHelper
  HIGHLIGHT = {
    backpage: 'text-warning',
    requester_only: 'text-warning',
    hidden: 'text-error'
  }.with_indifferent_access.freeze

  def prominence_icon(prominenceable)
    prominence = prominenceable.try(:prominence) || prominenceable
    tag.i class: "icon-prominence--#{ prominence }", title: prominence
  end

  def highlight_prominence(prominenceable)
    prominence = prominenceable.try(:prominence) || prominenceable
    return prominence unless HIGHLIGHT[prominence]
    tag.span prominence, class: HIGHLIGHT[prominence]
  end
end
