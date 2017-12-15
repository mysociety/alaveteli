module AlaveteliFeatures
  module SpecHelpers
    def with_feature_enabled(feature)
      allow(AlaveteliFeatures.backend).to receive(:enabled?).and_call_original
      allow(AlaveteliFeatures.backend).
        to receive(:enabled?).with(feature).and_return(true)
      yield if block_given?
    end

    def with_feature_disabled(feature)
      allow(AlaveteliFeatures.backend).to receive(:enabled?).and_call_original
      allow(AlaveteliFeatures.backend).
        to receive(:enabled?).with(feature).and_return(false)
      yield if block_given?
    end

    RSpec.configure do |config|
      config.before(:each) do |example|
        features = [example.metadata[:feature]].flatten
        next if features.empty?
        features.each { |f| with_feature_enabled(f) }
      end

      config.after(:each) do |example|
        features = [example.metadata[:feature]].flatten
        next if features.empty?
        features.each { |f| with_feature_disabled(f) }
      end
    end
  end
end
