module ConfigHelper
  def site_name
    AlaveteliConfiguration.site_name
  end

  def pro_site_name
    AlaveteliConfiguration.pro_site_name
  end

  def send_exception_notifications?
    !AlaveteliConfiguration.exception_notifications_from.blank? &&
      !AlaveteliConfiguration.exception_notifications_to.blank?
  end

  def blackhole_email
    AlaveteliConfiguration.blackhole_prefix+"@"+AlaveteliConfiguration.incoming_email_domain
  end
end
