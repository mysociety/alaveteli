# Helpers for handling prominence in the admin interface
module Admin::ProminenceHelper
  def prominence_icon(prominenceable)
    prominence = prominenceable.try(:prominence) || prominenceable
    tag.i class: "icon-prominence--#{ prominence }", title: prominence
  end
end
