module AlaveteliFeatures
  module SpecHelpers
    def with_feature_enabled(feature)
      allow(AlaveteliFeatures.backend).to receive(:enabled?).and_call_original
      allow(AlaveteliFeatures.backend).
        to receive(:enabled?).with(feature).and_return(true)
      yield
    end

    def with_feature_disabled(feature)
      allow(AlaveteliFeatures.backend).to receive(:enabled?).and_call_original
      allow(AlaveteliFeatures.backend).
        to receive(:enabled?).with(feature).and_return(false)
      yield
    end
  end
end
