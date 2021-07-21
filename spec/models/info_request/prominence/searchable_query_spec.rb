require 'spec_helper'

RSpec.describe InfoRequest::Prominence::SearchableQuery do

  describe '#call' do

    it 'returns only results with a normal prominence' do
      normal_request = FactoryBot.create(:info_request)
      hidden_request = FactoryBot.create(:info_request, :prominence => 'hidden')
      expect(described_class.new.call).to include(normal_request)
      expect(described_class.new.call).not_to include(hidden_request)
    end

    it 'does not return an embargoed request with normal prominence' do
      embargoed_request = FactoryBot.create(:embargoed_request)
      expect(described_class.new.call).not_to include(embargoed_request)
    end
  end

end
