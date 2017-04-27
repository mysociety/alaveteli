# -*- encoding : utf-8 -*-
module AlaveteliPro::InfoRequestsHelper
  def publish_at_options
    options = { _("Publish immediately") => '' }
    options.
      merge(AlaveteliPro::Embargo::TranslatedConstants.duration_labels.invert)
  end

  def embargo_extension_options(embargo)
    options = AlaveteliPro::Embargo::TranslatedConstants.
        duration_labels.to_a.map do |value, label|
      duration = AlaveteliPro::Embargo::DURATIONS[value].call
      expiry_date = embargo.publish_at + duration
      [label, value, "data-expiry-date" => I18n.l(embargo.publish_at, format: '%d %B %Y')]
    end
    options.unshift([_("Choose a duration"), ''])
  end
end
