require 'spec_helper'
require 'flipper/adapters/memory'
require 'alaveteli_features/helpers'
require_relative '../mocks/user'

RSpec.describe AlaveteliFeatures::Helpers do
  let(:instance) { Class.new { include AlaveteliFeatures::Helpers }.new }
  let(:test_backend) { Flipper.new(Flipper::Adapters::Memory.new) }

  around do |example|
    old_backend = AlaveteliFeatures.backend
    AlaveteliFeatures.backend = test_backend
    example.call
    AlaveteliFeatures.backend = old_backend
  end

  describe "#feature_enabled?" do
    it "should respond true when a feature is enabled" do
      AlaveteliFeatures.backend.enable(:test_feature)
      expect(instance.feature_enabled?(:test_feature)).to eq true
    end

    it "should respond false when a feature is disabled" do
      AlaveteliFeatures.backend.disable(:test_feature)
      expect(instance.feature_enabled?(:test_feature)).to eq false
    end

    it "should pass on other arguments to the backend" do
      user1 = MockUser.new(1)

      expect(AlaveteliFeatures.backend).to(
        receive(:enabled?).with(:test_feature, user1)
      )
      instance.feature_enabled?(:test_feature, user1)
    end
  end
end
