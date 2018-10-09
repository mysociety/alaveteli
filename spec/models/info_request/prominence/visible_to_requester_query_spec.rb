# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe InfoRequest::Prominence::VisibleToRequesterQuery do

  describe '#call' do

    it 'returns results with normal, backpaged or requester_only prominence' do
      normal_request = FactoryBot.create(:info_request)
      backpaged_request =
        FactoryBot.create(:info_request, prominence: 'backpage')
      requester_only_request =
        FactoryBot.create(:info_request, prominence: 'requester_only')
      hidden_request = FactoryBot.create(:info_request, prominence: 'hidden')
      requests = described_class.new.call
      expect(requests).to include(normal_request)
      expect(requests).to include(backpaged_request)
      expect(requests).to include(requester_only_request)
      expect(requests).not_to include(hidden_request)
    end

    it 'includes embargoed requests' do
      embargoed_request = FactoryBot.create(:embargoed_request)
      expect(described_class.new.call).to include(embargoed_request)
    end

  end

end
