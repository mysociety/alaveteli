# -*- encoding : utf-8 -*-
module ConfigHelper

  def site_name
    AlaveteliConfiguration::site_name
  end

  def send_exception_notifications?
    !AlaveteliConfiguration.exception_notifications_from.blank? &&
      !AlaveteliConfiguration.exception_notifications_to.blank?
  end

end
