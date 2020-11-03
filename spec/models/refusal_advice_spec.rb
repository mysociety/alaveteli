require 'spec_helper'

RSpec.describe RefusalAdvice do
  let(:data) do
    files = Dir.glob(Rails.root + 'spec/fixtures/refusal_advice/*.yml')
    RefusalAdvice::Store.from_yaml(files)
  end

  describe '.default' do
    subject { described_class.default }

    before do
      Rails.configuration.paths.add(
        'config/refusal_advice',
         with: Rails.root.join('spec/fixtures/refusal_advice'),
         glob: '*.yml'
      )
    end

    it { is_expected.to eq(described_class.new(data)) }
  end

  describe '#legislation' do
    let(:instance) { described_class.new(data) }
    subject { instance.legislation }

    let(:legislation) { double(:legislation) }

    before do
      allow(Legislation).to receive(:default).and_return(legislation)
    end

    it 'returns default legislation' do
      is_expected.to eq legislation
    end
  end

  describe '#questions' do
    let(:instance) { described_class.new(data) }
    subject { instance.questions }

    context 'for the FOI legislation' do
      before do
        allow(instance).to receive(:legislation).and_return(
          double(:legislation, key: :foi)
        )
      end

      let(:foi_questions) do
        [RefusalAdvice::Question.new(id: 'foo'),
         RefusalAdvice::Question.new(id: 'bar')]
      end

      it { is_expected.to eq(foi_questions) }
    end

    context 'for the EIR legislation' do
      before do
        allow(instance).to receive(:legislation).and_return(
          double(:legislation, key: :eir)
        )
      end

      let(:eir_questions) do
        [RefusalAdvice::Question.new(id: 'baz')]
      end

      it { is_expected.to eq(eir_questions) }
    end
  end

  describe '#actions' do
    let(:instance) { described_class.new(data) }
    subject { instance.actions }

    context 'for the FOI legislation' do
      before do
        allow(instance).to receive(:legislation).and_return(
          double(:legislation, key: :foi)
        )
      end

      let(:foi_actions) do
        [
          RefusalAdvice::Question.new(title: 'Hello World', suggestions: [
                                        { id: 'aaa' }, { id: 'bbb' }
                                      ])
        ]
      end

      it { is_expected.to eq(foi_actions) }
    end

    context 'for the EIR legislation' do
      before do
        allow(instance).to receive(:legislation).and_return(
          double(:legislation, key: :eir)
        )
      end

      let(:eir_actions) do
        [
          RefusalAdvice::Question.new(title: 'Hello World', suggestions: [
                                        { id: 'ccc' }
                                      ])
        ]
      end

      it { is_expected.to eq(eir_actions) }
    end
  end

  describe '#==' do
    subject { a == b }

    let(:data_a) { double }
    let(:data_b) { double }

    context 'with the same data' do
      let(:a) { described_class.new(data_a) }
      let(:b) { described_class.new(data_a) }
      it { is_expected.to eq(true) }
    end

    context 'with different data' do
      let(:a) { described_class.new(data_a) }
      let(:b) { described_class.new(data_b) }
      it { is_expected.to eq(false) }
    end
  end
end
