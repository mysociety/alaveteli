# -*- encoding : utf-8 -*-
module AlaveteliPro::InfoRequestsHelper
  def publish_at_options
    options = { _("Publish immediately") => '' }
    options.
      merge(AlaveteliPro::Embargo::TranslatedConstants.duration_labels.invert)
  end

  def embargo_extension_options(embargo)
    options = AlaveteliPro::Embargo::TranslatedConstants.
        duration_labels.map do |value, label|
      duration = AlaveteliPro::Embargo::DURATIONS[value].call
      expiry_date = I18n.l(embargo.publish_at + duration, format: '%d %B %Y')
      [label, value, "data-expiry-date" => expiry_date]
    end
    options.unshift([_("Choose a duration"), ''])
  end
end
