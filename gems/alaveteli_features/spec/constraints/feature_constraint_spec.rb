require 'spec_helper'

RSpec.describe AlaveteliFeatures::Constraints::FeatureConstraint do
  let(:test_backend) { Flipper.new(Flipper::Adapters::Memory.new) }

  around do |example|
    old_backend = AlaveteliFeatures.backend
    AlaveteliFeatures.backend = test_backend
    example.call
    AlaveteliFeatures.backend = old_backend
  end

  describe "#matches?" do
    it "should return true when a feature is enabled" do
      constraint = AlaveteliFeatures::Constraints::FeatureConstraint.new(:feature)
      allow(constraint).to receive(:feature_enabled?).with(:feature).and_return(true)
      expect(constraint.matches?(nil)).to be true
    end

    it "should return false when a feature is disabled" do
      constraint = AlaveteliFeatures::Constraints::FeatureConstraint.new(:feature)
      allow(constraint).to receive(:feature_enabled?).with(:feature).and_return(false)
      expect(constraint.matches?(nil)).to be false
    end
  end
end
