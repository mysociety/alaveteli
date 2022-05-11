require 'spec_helper'
require 'alaveteli_features/feature'
require_relative 'mocks/user'

RSpec.describe AlaveteliFeatures::Feature do
  let(:instance) { described_class.new(key: :feature) }

  describe '#key' do
    it 'requires argument when initializing' do
      expect(instance.key).to eq(:feature)
      expect { described_class.new }.to raise_error(ArgumentError)
    end
  end

  describe '#label' do
    it 'default to #key when initializing' do
      expect(instance.label).to eq(:feature)
    end

    it 'takes optional argument when initializing' do
      instance = described_class.new(key: :feature, label: 'Label')
      expect(instance.label).to eq('Label')
    end
  end

  describe '#to_sym' do
    subject { instance.to_sym }
    it { is_expected.to eq(:feature) }
  end

  describe '#with_actor' do
    let(:actor) { double }

    it 'sets actor' do
      expect { instance.with_actor(actor) }.to \
        change(instance, :actor).from(nil).to(actor)
    end

    it 'returns feature' do
      expect(instance.with_actor(actor)).to eq(instance)
    end
  end

  describe '#enabled?' do
    subject { instance.enabled? }

    let(:instance) { described_class.new(key: :feature).with_actor(actor) }
    let(:actor) { MockUser.new(1) }

    context 'without actor' do
      let(:actor) {}

      it 'raises ActorNotDefinedError' do
        expect { instance.enabled? }.to raise_error(
          AlaveteliFeatures::Feature::ActorNotDefinedError
        )
      end
    end

    context 'when feature enabled' do
      before { AlaveteliFeatures.backend.enable_actor(:feature, actor) }
      it { is_expected.to eq(true) }
    end

    context 'when feature disabled' do
      before { AlaveteliFeatures.backend.disable_actor(:feature, actor) }
      it { is_expected.to eq(false) }
    end
  end

  describe '#disabled?' do
    subject { instance.disabled? }

    let(:instance) { described_class.new(key: :feature).with_actor(actor) }
    let(:actor) { MockUser.new(1) }

    context 'without actor' do
      let(:actor) {}

      it 'raises ActorNotDefinedError' do
        expect { instance.disabled? }.to raise_error(
          AlaveteliFeatures::Feature::ActorNotDefinedError
        )
      end
    end

    context 'when feature enabled' do
      before { AlaveteliFeatures.backend.enable_actor(:feature, actor) }
      it { is_expected.to eq(false) }
    end

    context 'when feature disabled' do
      before { AlaveteliFeatures.backend.disable_actor(:feature, actor) }
      it { is_expected.to eq(true) }
    end
  end
end
