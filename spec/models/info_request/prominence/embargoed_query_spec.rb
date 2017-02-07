# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe InfoRequest::Prominence::EmbargoedQuery do

  describe '#call' do

    it 'limits the requests to those that have embargoes' do
      info_request = FactoryGirl.create(:info_request)
      embargoed_request = FactoryGirl.create(:embargoed_request)
      expect(described_class.new.call).to eq([embargoed_request])
    end

  end
end
