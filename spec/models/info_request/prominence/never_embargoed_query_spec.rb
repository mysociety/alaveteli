require 'spec_helper'

RSpec.describe InfoRequest::Prominence::NeverEmbargoedQuery do
  describe '#call' do
    subject { described_class.new.call }

    it 'limits the requests to those that have never been embargoed' do
      info_request = FactoryBot.create(:info_request)
      embargoed_request = FactoryBot.create(:embargoed_request)
      re_embargoed_request = FactoryBot.create(:re_embargoed_request)
      embargo_expired_request = FactoryBot.create(:embargo_expired_request)

      is_expected.to include info_request
      is_expected.to_not include embargoed_request
      is_expected.to_not include re_embargoed_request
      is_expected.to_not include embargo_expired_request
    end
  end
end
