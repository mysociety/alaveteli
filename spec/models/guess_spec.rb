require 'spec_helper'

RSpec.describe Guess do
  let(:info_request) do
    FactoryBot.create(:info_request, id: 100, idhash: '4e637388')
  end

  describe '.guessed_info_requests' do
    subject(:guesses) { described_class.guessed_info_requests(email) }

    let(:email) do
      mail = Mail.new
      mail.to address
      mail
    end

    let(:info_request) { FactoryBot.create(:info_request, id: 4566) }
    let!(:other_info_request) { FactoryBot.create(:info_request) }

    let(:id) { info_request.id }
    let(:hash) { info_request.idhash }

    context 'with email matching ID and ID hash' do
      let(:address) { info_request.incoming_email }

      it 'return matching InfoRequest' do
        is_expected.to match_array([info_request])
      end
    end

    context 'with email matching ID and almost ID hash' do
      let(:address) { "request-#{id}-#{hash[0...-1]}}z@localhost" }

      it 'return guessed InfoRequest' do
        is_expected.to match_array([info_request])
      end
    end

    context 'with email matching ID hash and almost ID' do
      let(:address) { "request-#{id.to_s[0...-1]}-#{hash}@localhost" }

      it 'return guessed InfoRequest' do
        is_expected.to match_array([info_request])
      end
    end
  end

  describe 'with a subject line given' do
    let(:guess) { described_class.new(info_request, subject: 'subject_line') }

    it 'returns an id_score of 0' do
      expect(guess.id_score).to eq(0)
    end

    it 'returns an idhash_score of 0' do
      expect(guess.idhash_score).to eq(0)
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
