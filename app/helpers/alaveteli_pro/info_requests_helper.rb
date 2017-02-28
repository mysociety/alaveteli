# -*- encoding : utf-8 -*-
module AlaveteliPro::InfoRequestsHelper
  def publish_at_options
    options = { _("Publish immediately") => '' }
    options.merge(AlaveteliPro::Embargo::DURATION_LABELS.invert)
  end

  def embargo_extension_options
    AlaveteliPro::Embargo::DURATION_LABELS.invert
  end
end
