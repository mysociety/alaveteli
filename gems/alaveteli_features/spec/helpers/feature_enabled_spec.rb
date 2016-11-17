require 'spec_helper'
require 'flipper/adapters/memory'
require 'alaveteli_features/helpers'

describe AlaveteliFeatures::Helpers do
  let(:instance) { Class.new { include AlaveteliFeatures::Helpers }.new }
  let(:test_backend) { Flipper.new(Flipper::Adapters::Memory.new) }
  let(:user_class) do
    # A test class to let us test the actor-based feature flipping
    class User
      attr_reader :id

      def initialize(id, admin)
        @id = id
        @admin = admin
      end

      def admin?
        @admin
      end

      # Must respond to flipper_id
      alias_method :flipper_id, :id
    end
  end

  before do
    AlaveteliFeatures.backend = test_backend
    # Seems to be the only way to make sure we don't register a group twice
    begin
      AlaveteliFeatures.backend.group(:admins)
    rescue Flipper::GroupNotRegistered
      Flipper.register :admins do |actor|
        actor.respond_to?(:admin?) && actor.admin?
      end
    end
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
      user1 = user_class.new(1, true)

      mock_backend = double("backend")
      AlaveteliFeatures.backend = mock_backend

      expect(mock_backend).to(
        receive(:enabled?).with(:test_feature, user1)
      )
      instance.feature_enabled?(:test_feature, user1)
    end
  end
end
