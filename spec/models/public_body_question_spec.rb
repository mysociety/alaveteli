require 'spec_helper'

RSpec.describe PublicBodyQuestion do
  let(:public_body) { FactoryBot.build(:public_body) }
  let(:args) do
    {
      public_body: public_body,
      key: :foi,
      question: 'Is this an FOI?',
      response: 'A custom response'
    }
  end
  let(:question) { described_class.new(args) }

  describe '.build' do
    it 'initialise and store new instance' do
      all = described_class.build(args)
      expect(all).to include(described_class)
    end
  end

  describe '.fetch' do
    before { described_class.build(args) }

    it 'returns instances for given public body' do
      questions = described_class.fetch(public_body)
      expect(questions).to be_an(Array)
      expect(questions.count).to eq(1)
      expect(questions.first).to be_a(described_class)
    end

    it 'returns an empty array if there are no instances' do
      questions = described_class.fetch(nil)
      expect(questions).to match_array([])
    end
  end

  describe 'initialisation' do
    it 'should not raise error if allow required arguments are given' do
      expect { described_class.new(args) }.not_to raise_error
    end

    it 'requires public_body argument' do
      args_without_public_body = args.reject { |k| k == :public_body }
      expect { described_class.new(args_without_public_body) }.
        to raise_error(KeyError, 'key not found: :public_body')
    end

    it 'requires key argument' do
      args_without_key = args.reject { |k| k == :key }
      expect { described_class.new(args_without_key) }.
        to raise_error(KeyError, 'key not found: :key')
    end

    it 'requires question argument' do
      args_without_question = args.reject { |k| k == :question }
      expect { described_class.new(args_without_question) }.
        to raise_error(KeyError, 'key not found: :question')
    end

    it 'requires response argument' do
      args_without_response = args.reject { |k| k == :response }
      expect { described_class.new(args_without_response) }.
        to raise_error(KeyError, 'key not found: :response')
    end
  end

  describe '#public_body' do
    it { expect(question.public_body).to eq(public_body) }
  end

  describe '#key' do
    it { expect(question.key).to eq(:foi) }
  end

  describe '#text' do
    it { expect(question.text).to eq('Is this an FOI?') }
  end

  describe '#response' do
    it { expect(question.response).to eq('A custom response') }
  end

  describe '#action' do
    context 'when response is set to allow' do
      before { allow(question).to receive(:response).and_return(:allow) }
      it { expect(question.action).to eq(:allow) }
    end

    context 'when response is set to something other than allow' do
      before { allow(question).to receive(:response).and_return('NOPE') }
      it { expect(question.action).to eq(:deny) }
    end
  end
end
