# -*- encoding : utf-8 -*-
module AdminPublicBodyCategoryHelper
  def heading_is_selected?(heading)
    if params[:headings]
      if params[:headings]["heading_#{heading.id}"]
        return true
      else
        return false
      end
    elsif @public_body_category.public_body_headings.include?(heading)
      return true
    end
    false
  end
end
