require 'spec_helper'

RSpec.describe AlaveteliPro::Access do
  describe '.grant' do

    it 'initialise instance' do
      args = [double(:arg1), double(:arg2)]
      block = -> { double(:block) }
      expect(described_class).to receive(:new).with(*args) do |&received_block|
        expect(received_block).to eq(block)
        double.as_null_object
      end
      described_class.grant(*args, &block)
    end

    it 'returns #grant' do
      result = double('return value')
      instance = double(described_class, grant: result)
      allow(described_class).to receive(:new).and_return(instance)
      expect(described_class.grant).to eq(instance.grant)
    end

  end

  describe '.new' do

    it 'assigns #user' do
      user = double(:user)
      instance = described_class.new(user)
      expect(instance.user).to eq(user)
    end

  end

  describe '#grant' do
    let(:user) { FactoryBot.build(:user) }
    let(:instance) { described_class.new(user) }

    def feature_enabled?(feature, user)
      AlaveteliFeatures.backend[feature].enabled?(user)
    end

    it 'does not enable pop polling by default' do
      expect { instance.grant }.to_not change {
        feature_enabled?(:accept_mail_from_poller, user)
      }
    end

    it 'enables daily summary notifications for the user' do
      expect { instance.grant }.to change {
        feature_enabled?(:notifications, user)
      }.to(true)
    end

    it 'enables batch for the user' do
      expect { instance.grant }.to change {
        feature_enabled?(:pro_batch_access, user)
      }.to(true)
    end

    context 'when pop polling is enabled' do

      before do
        allow(AlaveteliConfiguration).
          to receive(:production_mailer_retriever_method).
          and_return('pop')
      end

      it 'enables pop polling for the user' do
        expect { instance.grant }.to change {
          feature_enabled?(:accept_mail_from_poller, user)
        }.to(true)
      end

    end
  end
end
