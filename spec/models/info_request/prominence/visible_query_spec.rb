# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe InfoRequest::Prominence::VisibleQuery do

  describe '#call' do

    it 'returns only results with a normal prominence' do
      normal_request = FactoryGirl.create(:info_request)
      hidden_request = FactoryGirl.create(:info_request, :prominence => 'hidden')
      expect(described_class.new.call).to include(normal_request)
      expect(described_class.new.call).not_to include(hidden_request)
    end

    it 'does not return an embargoed request with normal prominence' do
      embargoed_request = FactoryGirl.create(:embargoed_request)
      expect(described_class.new.call).not_to include(embargoed_request)
    end
  end

end
