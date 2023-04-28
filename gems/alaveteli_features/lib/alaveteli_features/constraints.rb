module AlaveteliFeatures
  module Constraints
    class FeatureConstraint
      include AlaveteliFeatures::Helpers

      def initialize(feature)
        @feature = feature
      end

      def matches?(_request)
        feature_enabled? @feature
      end
    end
  end
end
