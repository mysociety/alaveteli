# -*- encoding : utf-8 -*-
module HealthChecksHelper

  def check_status(check)
    style = check.ok? ? '' : 'color: red'
    content_tag(:b, check.message, :style => style)
  end

end
