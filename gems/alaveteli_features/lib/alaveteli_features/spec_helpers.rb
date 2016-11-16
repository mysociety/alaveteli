module AlaveteliFeatures
  module SpecHelpers
    def with_feature_enabled(feature)
      allow(AlaveteliFeatures.backend).
        to receive(:enabled?).with(feature).and_return(true)
      yield
    ensure
      allow(AlaveteliFeatures.backend).
        to receive(:enabled?).with(feature).and_call_original
    end

    def with_feature_disabled(feature)
      allow(AlaveteliFeatures.backend).
        to receive(:enabled?).with(feature).and_return(false)
      yield
    ensure
      allow(AlaveteliFeatures.backend).
        to receive(:enabled?).with(feature).and_call_original
    end
  end
end