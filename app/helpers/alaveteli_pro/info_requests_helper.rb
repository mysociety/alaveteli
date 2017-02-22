# -*- encoding : utf-8 -*-
module AlaveteliPro::InfoRequestsHelper
  def publish_at_options
    options = { _("Publish immediately") => '' }
    options.merge(AlaveteliPro::Embargo::DURATION_LABELS.invert)
  end

  def embargo_extension_options(embargo)
    options = AlaveteliPro::Embargo::DURATION_LABELS.map do |value, label|
      duration = AlaveteliPro::Embargo::DURATIONS[value].call
      expiry_date = embargo.publish_at + duration
      [label, value, "data-expiry-date" => expiry_date.strftime('%d %B %Y')]
    end
  end
end
