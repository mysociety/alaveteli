require 'spec_helper'

RSpec.describe RefusalAdvice::Store do
  let(:fixture_data) do
    [
      # spec/fixtures/refusal_advice/data/eir.yml
      { eir: { group: [{ id: 'foo' }] } },
      # spec/fixtures/refusal_advice/data/foi.yml
      {
        foi: {
          group: [
            { id: 'foo' },
            { id: 'baz' },
            { id: 'with_subgroup', subgroup: [{ id: 'xyz' }] }
          ]
        }
      },
      # spec/fixtures/refusal_advice/data/foi_and_eir.yml
      {
        foi: {
          group: [
            { id: 'bar' },
            { id: 'with_subgroup', subgroup: [{ id: 'abc' }] }
          ]
        },
        eir: { group: [{ id: 'bar' }] }
      }
    ].map(&:deep_stringify_keys)
  end

  describe '.from_yaml' do
    let(:glob) do
      Dir.glob(Rails.root + 'spec/fixtures/refusal_advice/data/*.yml')
    end
    subject { described_class.from_yaml(glob) }

    it { is_expected.to eq(described_class.new(fixture_data)) }
  end

  describe '#[]' do
    subject { described_class.new(fixture_data)[key] }

    context 'with a symbol key' do
      let(:key) { :eir }
      it { is_expected.to eq(group: [{ id: 'foo' }, { id: 'bar' }]) }
    end

    context 'with a string key' do
      let(:key) { 'eir' }
      it { is_expected.to eq(group: [{ id: 'foo' }, { id: 'bar' }]) }
    end
  end

  describe '#to_h' do
    subject { described_class.new(fixture_data).to_h }

    it 'merges the data in each globbed file into a hash' do
      expected = {
        foi: {
          group: [
            { id: 'foo' },
            { id: 'baz' },
            { id: 'with_subgroup', subgroup: [{ id: 'xyz' }, { id: 'abc' }] },
            { id: 'bar' }
          ]
        },
        eir: {
          group: [
            { id: 'foo' },
            { id: 'bar' }
          ]
        }
      }

      is_expected.to eq(expected)
    end
  end

  describe '#==' do
    subject { a == b }

    context 'with the same data' do
      let(:a) { described_class.new(foo: 'bar') }
      let(:b) { described_class.new(foo: 'bar') }
      it { is_expected.to eq(true) }
    end

    context 'with different data' do
      let(:a) { described_class.new(foo: 'bar') }
      let(:b) { described_class.new(bar: 'foo') }
      it { is_expected.to eq(false) }
    end
  end
end
