# -*- encoding : utf-8 -*-
module AlaveteliPro::DashboardHelper
  def activity_item_description(activity_item)
    _(activity_item.description, description_urls(activity_item))
  end

  def description_urls(activity_item)
    activity_item.description_urls.inject({}) do |hash, (key, value)|
      hash[key] = link_to value[:text], value[:url]
      hash
    end
  end
end
