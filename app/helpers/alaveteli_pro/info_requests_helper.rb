# -*- encoding : utf-8 -*-
module AlaveteliPro::InfoRequestsHelper
  def embargo_publish_at(embargo)
    return unless embargo && embargo.publish_at
    I18n.l(embargo.publish_at, format: '%-d %B %Y')
  end

  def embargo_extend_from(embargo)
    return unless embargo && embargo.publish_at
    I18n.l(embargo.calculate_expiring_notification_at, format: '%-d %B %Y')
  end

  def publish_at_options
    options = embargo_options_from_date(Date.today)
    options.unshift([_('Publish immediately'), ''])
  end

  def embargo_extension_options(embargo = nil)
    options = embargo_options_from_date(embargo&.publish_at || Date.today)
    options.unshift([_('Choose a duration'), ''])
  end

  private

  def embargo_options_from_date(start_date)
    AlaveteliPro::Embargo::TranslatedConstants.
        duration_labels.map do |value, label|
      duration = AlaveteliPro::Embargo::DURATIONS[value].call
      expiry_date = I18n.l(start_date + duration, format: '%d %B %Y')
      [label, value, 'data-expiry-date' => expiry_date]
    end
  end
end
