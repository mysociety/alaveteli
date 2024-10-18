require 'spec_helper'

describe AlaveteliPro::AccountHelper do
  describe '#card_expiry_message' do
    it 'returns expiry message when card expires this month' do
      allow(Date).to receive(:today).and_return(Date.new(2023, 5, 1))
      expect(helper.card_expiry_message(5, 2023)).to eq('<p class="card__expiring">Expires soon</p>')
    end

    it 'returns nil when card does not expire this month' do
      allow(Date).to receive(:today).and_return(Date.new(2023, 5, 1))
      expect(helper.card_expiry_message(6, 2023)).to be_nil
    end
  end
end
