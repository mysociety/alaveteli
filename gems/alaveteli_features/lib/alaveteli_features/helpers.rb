module AlaveteliFeatures
  module Helpers
    def feature_enabled?(feature, *args)
      AlaveteliFeatures.backend.enabled?(feature, *args)
    end
  end
end
