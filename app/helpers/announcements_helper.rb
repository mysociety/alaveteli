module AnnouncementsHelper
  def announcement_as_html(announcement)
    sanitize(announcement.rich_body.to_trix_html)
  end

  def announcement_style_class(announcement)
    "announcement--style-#{announcement.style}"
  end

  ADMIN_ALERT_CLASSES = {
    'red' => 'alert-error',
    'yellow' => 'alert-warning',
    'green' => 'alert-success'
  }.freeze

  def announcement_admin_alert_class(announcement)
    ADMIN_ALERT_CLASSES.fetch(announcement.style, 'alert-info')
  end
end
