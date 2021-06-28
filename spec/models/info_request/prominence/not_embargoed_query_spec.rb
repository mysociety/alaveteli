require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe InfoRequest::Prominence::NotEmbargoedQuery do

  describe '#call' do

    it 'limits the requests to those that do not have embargoes' do
      embargoed_request = FactoryBot.create(:embargoed_request)
      expect(described_class.new.call).not_to include(embargoed_request)
    end

  end
end
