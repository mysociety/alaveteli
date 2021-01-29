require 'spec_helper'

RSpec.describe RefusalAdvice do
  let(:data) do
    files = Dir.glob(Rails.root + 'spec/fixtures/refusal_advice/*.yml')
    RefusalAdvice::Store.from_yaml(files)
  end

  describe '.default' do
    subject { described_class.default }

    let(:path) { Rails.root.join('spec/fixtures/refusal_advice') }

    before do
      Rails.configuration.paths['config/refusal_advice'].push(path)
    end

    after do
      Rails.configuration.paths['config/refusal_advice'].unshift(path)
    end

    context 'with info request' do
      subject { described_class.default(info_request) }
      let(:info_request) { FactoryBot.build(:info_request) }

      it do
        is_expected.to eq(
          described_class.new(data, info_request: info_request)
        )
      end
    end

    context 'without info request' do
      it { is_expected.to eq(described_class.new(data)) }
    end
  end

  describe '#legislation' do
    let(:instance) { described_class.new(data, info_request: info_request) }
    subject { instance.legislation }

    let(:legislation) { double(:legislation) }

    context 'with info request' do
      let(:info_request) { FactoryBot.build(:info_request) }

      it 'returns info request legislation' do
        allow(info_request).to receive(:legislation).and_return(legislation)
        is_expected.to eq legislation
      end
    end

    context 'without info request' do
      let(:info_request) { nil }

      it 'returns default legislation' do
        allow(Legislation).to receive(:default).and_return(legislation)
        is_expected.to eq legislation
      end
    end
  end

  describe '#questions' do
    let(:instance) { described_class.new(data) }
    subject { instance.questions }

    context 'for the FOI legislation' do
      before do
        allow(instance).to receive(:legislation).and_return(
          double(:legislation, to_sym: :foi)
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
          double(:legislation, to_sym: :eir)
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
          double(:legislation, to_sym: :foi)
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
          double(:legislation, to_sym: :eir)
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

  context '#snippets' do
    subject { instance.snippets }

    let(:scope) { double(:outgoing_message_snippet_scope) }
    let(:snippets) { [FactoryBot.build(:outgoing_message_snippet)] }

    before do
      allow(OutgoingMessage::Snippet).to receive(:with_tag).
        with('refusal_advice').and_return(scope)
    end

    context 'when sending a follow up message' do
      let(:instance) { described_class.new(data, internal_review: false) }

      it 'assigns refusal advice snippets' do
        expect(scope).to receive(:without_tag).with('internal_review').
          and_return(snippets)

        is_expected.to eq snippets
      end
    end

    context 'when sending an internal review' do
      let(:instance) { described_class.new(data, internal_review: true) }

      it 'assigns refusal advice snippets' do
        expect(scope).to receive(:with_tag).with('internal_review').
          and_return(snippets)

        is_expected.to eq snippets
      end
    end
  end

  context '#answers' do
    subject { instance.answers }

    let(:user) { FactoryBot.build(:user) }
    let(:info_request) { FactoryBot.create(:info_request, user: user) }

    let(:instance) do
      described_class.new(data, info_request: info_request, user: user)
    end

    context 'when info request event has been stored' do
      let!(:event) do
        FactoryBot.create(:refusal_advice_event, info_request: info_request)
      end

      it { is_expected.to match_array(['refusal_advice:action_3']) }
    end

    context 'when there is no info request event stored' do
      it { is_expected.to be_nil }
    end
  end

  context '#filter_options' do
    subject { instance.filter_options }

    let(:info_request) { FactoryBot.create(:info_request) }

    let(:instance) do
      described_class.new(data, info_request: info_request)
    end

    before do
      allow(instance).to receive(:legislation).and_return(
        FactoryBot.build(:legislation, refusals: ['s 11', 's 12'])
      )
      allow(instance).to receive(:snippets).and_return(
        double(:outgoing_message_snippet_scope,
               tags: 'refusal:section-12 refusal:section-14')
      )
    end

    it 'returns options array of legislation refusals tags which are active' do
      is_expected.to match_array([['Section 12', 'refusal:section-12']])
    end
  end
end
