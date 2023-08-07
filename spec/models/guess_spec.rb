require 'spec_helper'

RSpec.describe Guess do
  let(:info_request) do
    FactoryBot.create(:info_request, id: 100, idhash: '4e637388')
  end

  describe 'with a subject line given' do
    let(:guess) { described_class.new(info_request, subject: 'subject_line') }

    it 'returns an id_score of 1' do
      expect(guess.id_score).to eq(1)
    end

    it 'returns an idhash_score of 1' do
      expect(guess.idhash_score).to eq(1)
    end
  end

  describe 'with an id given' do
    let(:guess_1) { described_class.new(info_request, id: 100) }
    let(:guess_2) { described_class.new(info_request, id: 456) }
    let(:guess_3) { described_class.new(info_request, id: 109) }

    it 'returns an id_score of 1 when it is correct' do
      expect(guess_1.id_score).to eq(1.0)
    end

    it 'returns an id_score of 0 when there is no similarity' do
      expect(guess_2.id_score).to eq(0.0)
    end

    it 'returns a value between 0 and 1 when there is some similarity' do
      expect(guess_3.id_score).to be_between(0, 1).exclusive
    end
  end

  describe 'with an idhash given' do
    let(:guess_1) { described_class.new(info_request, idhash: '4e637388') }
    let(:guess_2) { described_class.new(info_request, idhash: '12345678') }
    let(:guess_3) { described_class.new(info_request, idhash: '4e637399') }

    it 'returns an idhash_score of 1 when it is correct' do
      expect(guess_1.idhash_score).to eq(1.0)
    end

    it 'returns an idhash_score of 0 when there is no similarity' do
      expect(guess_2.idhash_score).to eq(0.0)
    end

    it 'returns a value between 0 and 1 when there is some similarity' do
      expect(guess_3.idhash_score).to be_between(0, 1).exclusive
    end
  end
end
