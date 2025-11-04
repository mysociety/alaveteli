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
      def extract_features(metadata)
        features = metadata[:feature] || metadata[:features]
        return unless features
        return features if features.is_a?(Hash)

        features = Array(features).map { [_1, true] }.to_h
      end

      config.before(:each) do |example|
        features = extract_features(example.metadata)
        next unless features

        @original_feature_state = {}
        features.each do |feature, enabled|
          @original_feature_state[feature] = AlaveteliFeatures.backend.
            enabled?(feature)
          if enabled
            with_feature_enabled(feature)
          else
            with_feature_disabled(feature)
          end
        end
      end

      config.after(:each) do |example|
        features = extract_features(example.metadata)
        next unless features

        features.each do |feature, _enabled|
          if @original_feature_state[feature]
            with_feature_enabled(feature)
          else
            with_feature_disabled(feature)
          end
        end
      end
    end
  end
end
