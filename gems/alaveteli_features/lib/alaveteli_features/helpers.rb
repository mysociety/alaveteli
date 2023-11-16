module AlaveteliFeatures
  module Helpers
    def feature_enabled?(feature, *args)
      AlaveteliFeatures.backend.enabled?(feature, *args)
    end

    def enable_actor(feature, user)
      # check feature hasn't already been enabled for the user
      return true if feature_enabled?(feature, user)

      AlaveteliFeatures.backend.enable_actor(feature, user)
    end

    def disable_actor(feature, user)
      # check feature isn't already been disabled for the user
      return true unless feature_enabled?(feature, user)

      AlaveteliFeatures.backend.disable_actor(feature, user)
    end
  end
end
