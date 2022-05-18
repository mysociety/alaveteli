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

  describe '#enable_actor' do
    let(:user) { MockUser.new(1) }

    it 'should respond true when an actor already enabled' do
      AlaveteliFeatures.backend.enable_actor(:test_feature, user)
      expect(instance.enable_actor(:test_feature, user)).to eq(true)
    end

    it 'should respond true when an actor is enabled' do
      expect(instance.enable_actor(:test_feature, user)).to eq(true)
    end

    context 'persisted backend' do
      let(:test_backend) do
        skip('Rails and database connection required') unless defined?(Rails)
        Flipper.new(Flipper::Adapters::ActiveRecord.new)
      end

      it 'does not raise PG::UniqueViolation if actor is already enabled' do
        AlaveteliFeatures.backend.enable_actor(:test_feature, user)
        expect { instance.enable_actor(:test_feature, user) }.not_to raise_error
      end
    end
  end
end
