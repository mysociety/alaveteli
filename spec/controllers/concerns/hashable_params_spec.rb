require 'spec_helper'

describe HashableParams do
  include HashableParams

  describe '#params_to_unsafe_hash' do
    subject { params_to_unsafe_hash(raw_params) }

    context 'passed an empty hash' do
      let(:raw_params) { {} }
      it { is_expected.to eq({}) }
    end

    context 'passed nil' do
      let(:raw_params) { nil }
      it { is_expected.to eq({}) }
    end

    context 'passed a populated hash' do
      let(:raw_params) { { foo: 1, bar: 2 } }

      it 'raises an error' do
        expect { subject }.to raise_error(NoMethodError)
      end
    end

    context 'passed an instance of ActionController::Parameters' do
      let(:params_hash) { { foo: "1", bar: "false" } }
      let(:raw_params) { ActionController::Parameters.new(params_hash) }

      it 'does not strip unpermitted keys' do
        expect(subject.keys).to match_array(['foo', 'bar'])
      end

      it 'returns a hash' do
        expect(subject).to be_a(Hash)
      end

      it 'returns a hash which responds to #with_indifferent_access' do
        expect(subject).to respond_to(:with_indifferent_access)
      end
    end

  end

end
