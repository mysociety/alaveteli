# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe InfoRequest::Prominence::PublicQuery do

  describe '#call' do

    it 'returns only results with a normal or backpaged prominence' do
      normal_request = FactoryGirl.create(:info_request)
      backpaged_request = FactoryGirl.create(:info_request, :prominence => 'backpage')
      hidden_request = FactoryGirl.create(:info_request, :prominence => 'hidden')
      requests = described_class.new.call
      expect(requests).to include(normal_request)
      expect(requests).to include(backpaged_request)
      expect(requests).not_to include(hidden_request)
    end

    it 'does not return an embargoed request' do
      embargoed_request = FactoryGirl.create(:embargoed_request)
      expect(described_class.new.call).not_to include(embargoed_request)
    end
  end

end