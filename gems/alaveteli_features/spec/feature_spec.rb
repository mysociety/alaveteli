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

  describe '#condition' do
    it 'default to black evaluating to true when initializing' do
      expect(instance.condition.call).to eq(true)
    end

    it 'takes optional argument when initializing' do
      instance = described_class.new(key: :eature, condition: -> { false })
      expect(instance.condition.call).to eq(false)
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

  describe '#roles=' do
    let(:roles) { [double] }

    it 'sets roles' do
      expect { instance.roles = roles }.to \
        change(instance, :roles).from([]).to(roles)
    end
  end

  describe '#roles' do
    it 'defaults to an empty array' do
      expect(instance.roles).to eq([])
    end
  end

  describe '#roles?' do
    subject { instance.roles? }

    context 'with roles' do
      before { instance.roles = [double] }
      it { is_expected.to eq(true) }
    end

    context 'without roles' do
      it { is_expected.to eq(false) }
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

  describe '#enable' do
    let(:instance) { described_class.new(key: :feature).with_actor(actor) }
    let(:actor) { MockUser.new(1) }

    context 'without actor' do
      let(:actor) {}

      it 'raises ActorNotDefinedError' do
        expect { instance.enable }.to raise_error(
          AlaveteliFeatures::Feature::ActorNotDefinedError
        )
      end
    end

    context 'with actor' do
      it 'enables feature for actor' do
        expect { instance.enable }.to \
          change { AlaveteliFeatures.backend.enabled?(:feature, actor) }.
          from(false).to(true)
      end
    end
  end

  describe '#disable' do
    let(:instance) { described_class.new(key: :feature).with_actor(actor) }
    let(:actor) { MockUser.new(1) }

    context 'without actor' do
      let(:actor) {}

      it 'raises ActorNotDefinedError' do
        expect { instance.disable }.to raise_error(
          AlaveteliFeatures::Feature::ActorNotDefinedError
        )
      end
    end

    context 'with actor' do
      it 'disables feature for actor' do
        AlaveteliFeatures.backend.enable_actor(:feature, actor)
        expect { instance.disable }.to \
          change { AlaveteliFeatures.backend.enabled?(:feature, actor) }.
          from(true).to(false)
      end
    end
  end
end
