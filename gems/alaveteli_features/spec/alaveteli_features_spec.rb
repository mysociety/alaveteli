require 'spec_helper'
require 'flipper/adapters/memory'

describe AlaveteliFeatures do
  it 'should have a version number' do
    expect(AlaveteliFeatures::VERSION).not_to be_nil
  end

  it 'should allow you to access the backend' do
    expect(AlaveteliFeatures.backend).not_to be_nil
  end

  it 'should allow you to set the backend' do
    test_backend = Flipper.new(Flipper::Adapters::Memory.new)
    AlaveteliFeatures.backend = test_backend
    expect(AlaveteliFeatures.backend).to be test_backend
  end
end
