require 'spec_helper'

describe InfoRequest::Prominence::BeenPublishedQuery do

  describe '#call' do
    subject { described_class.new.call }

    it 'limits the requests to those that do not have embargoes or whose embargoes have been expired in the past' do
      info_request = FactoryBot.create(:info_request)
      embargoed_request = FactoryBot.create(:embargoed_request)
      re_embargoed_request = FactoryBot.create(:re_embargoed_request)

      is_expected.to include info_request
      is_expected.to include re_embargoed_request
      is_expected.to_not include embargoed_request
    end

  end
end
