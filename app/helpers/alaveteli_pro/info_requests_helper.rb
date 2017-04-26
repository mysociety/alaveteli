# -*- encoding : utf-8 -*-
module AlaveteliPro::InfoRequestsHelper
  def publish_at_options
    options = { _("Publish immediately") => '' }
    options.
      merge(AlaveteliPro::Embargo::TranslatedConstants.duration_labels.invert)
  end

  def embargo_extension_options
    AlaveteliPro::Embargo::TranslatedConstants.duration_labels.invert
  end
end
